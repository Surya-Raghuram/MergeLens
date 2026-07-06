import os
import json
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage
from langgraph.graph import StateGraph, START, END

from app.analyzer.state import ReviewState
from app.analyzer.wrapper import analyze_file

# Initialize Gemini (Flash is the best balance of speed/cost/logic for code review)
llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash", temperature=0.2)

# --- NODES ---

async def router_node(state: ReviewState) -> ReviewState:
    file_path = state["file_path"]
    ext = file_path.split(".")[-1] if "." in file_path else ""
    
    supported_extensions = {"py", "cpp", "hpp", "cc", "h"}
    
    if ext in supported_extensions:
        cpp_res = await analyze_file(file_path)
        state["cpp_structure"] = cpp_res if "error" not in cpp_res else None
        state["language"] = ext
        state["next_step"] = "analyst"
    else:
        state["cpp_structure"] = None
        state["language"] = "text"
        state["next_step"] = "reviewer"
        
    return state


async def analyst_node(state: ReviewState) -> ReviewState:
    cpp_struct = json.dumps(state["cpp_structure"], indent=2)
    patch = state["patch"]
    
    prompt = f"""
    You are an expert software architect. Analyze this code modification patch using the code structure map provided by a native AST parser.
    Identify the scope of the change: which classes or functions are directly impacted or broken by this modification.
    
    AST Code Structure Map:
    {cpp_struct}
    
    Git Patch:
    {patch}
    
    Output a concise summary of the architectural impact, logic modifications, and potential risk factors.
    """
    
    response = await llm.ainvoke([HumanMessage(content=prompt)])
    state["structural_intent"] = response.content
    state["next_step"] = "reviewer"
    return state


async def reviewer_node(state: ReviewState) -> ReviewState:
    patch = state["patch"]
    intent = state.get("structural_intent", "No architectural changes detected.")
    
    prompt = f"""
    You are a meticulous Code Reviewer. Generate helpful, precise code review suggestions in strict JSON format.
    Focus on code quality, logic bugs, performance traps, and edge-case failures.
    
    Architectural Context:
    {intent}
    
    Git Patch:
    {patch}
    
    Your output MUST be a valid JSON array matching this format exactly:
    [
      {{"line": 14, "comment": "Consider adding validation here to prevent null pointer exceptions."}},
      {{"line": 22, "comment": "This loop operation is performance heavy, optimize where possible."}}
    ]
    Do not wrap your output in markdown text blocks or provide conversational text; output strictly valid JSON syntax.
    """
    
    response = await llm.ainvoke([HumanMessage(content=prompt)])
    
    # Safely extract and parse the JSON array from the LLM response
    clean_content = response.content.strip().replace("```json", "").replace("```", "")
    try:
        state["review_comments"] = json.loads(clean_content)
    except Exception:
        state["review_comments"] = [{"line": 0, "comment": "Failed to parse structured review feedback.", "raw": clean_content}]
        
    state["next_step"] = "end"
    return state

# --- ROUTING LOGIC ---
def route_decision(state: ReviewState) -> str:
    return state["next_step"]

# --- GRAPH CONSTRUCTION ---
workflow = StateGraph(ReviewState)
workflow.add_node("router", router_node)
workflow.add_node("analyst", analyst_node)
workflow.add_node("reviewer", reviewer_node)

workflow.add_edge(START, "router")
workflow.add_conditional_edges("router", route_decision, {"analyst": "analyst", "reviewer": "reviewer"})
workflow.add_conditional_edges("analyst", route_decision, {"reviewer": "reviewer"})
workflow.add_conditional_edges("reviewer", route_decision, {"end": END})

review_brain = workflow.compile()