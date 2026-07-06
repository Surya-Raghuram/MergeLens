import os
import tempfile
from arq.connections import RedisSettings
from app.core.config import settings
from app.services.github_client import get_pull_request_files, publish_review_comments
from app.analyzer.graph import review_brain
from app.core.supabase_client import supabase

async def process_pull_request(ctx: dict, pr_number: int, repo_name: str) -> str:
    """
    Background job that orchestrates the entire autonomous review pipeline.
    """
    print(f"[PR #{pr_number}] 🚀 Starting MergeLens analysis for: {repo_name}")
    
    try:
        # 1. Fetch changed files and their raw contents from GitHub
        files = get_pull_request_files(repo_name, pr_number)
        print(f"[PR #{pr_number}] Found {len(files)} actionable file(s).")
        
        # We use a temporary directory so the C++ analyzer has physical files to read,
        # which are automatically cleaned up when the 'with' block exits.
        with tempfile.TemporaryDirectory() as temp_dir:
            for f in files:
                filename = f["filename"]
                patch = f["patch"]
                content = f["content"]
                
                print(f"[PR #{pr_number}] Analyzing: {filename}...")
                
                # Write the file to disk temporarily
                temp_filepath = os.path.join(temp_dir, os.path.basename(filename))
                with open(temp_filepath, "w", encoding="utf-8") as temp_file:
                    temp_file.write(content)
                
                # 2. Prepare state for LangGraph
                state_input = {
                    "file_path": temp_filepath, # Pass the temp file path for C++ analyzer
                    "patch": patch,
                    "language": "",
                    "cpp_structure": None,
                    "structural_intent": None,
                    "review_comments": [],
                    "next_step": ""
                }
                
                # 3. Execute the Multi-Agent Brain
                final_state = await review_brain.ainvoke(state_input)
                comments = final_state.get("review_comments", [])
                
                if comments:
                    print(f"[PR #{pr_number}] Generated {len(comments)} comments for {filename}. Publishing to GitHub...")
                    
                    # 4. Publish to GitHub using the original filename, not the temp path
                    publish_review_comments(
                        repo_name=repo_name,
                        pr_number=pr_number,
                        file_path=filename,
                        comments=comments
                    )
                else:
                    print(f"[PR #{pr_number}] Code looks good. No comments generated for {filename}.")

                try:
                    supabase.table("review_reports").insert({
                        "repo_name": repo_name,
                        "pr_number": pr_number,
                        "status": "completed" if comments else "clean",
                        "file_changes_summary": final_state.get("structural_intent", "No major structural changes."),
                        "structural_comments": comments
                    }).execute()
                    print(f"[PR #{pr_number}] 💾 Saved report to Supabase.")
                except Exception as db_err:
                    print(f"[PR #{pr_number}] ⚠️ Failed to save to DB: {db_err}")
                    
        print(f"[PR #{pr_number}] ✅ Review complete.")
        return f"Successfully processed {repo_name} PR #{pr_number}"
        
    except Exception as e:
        print(f"[PR #{pr_number}] ❌ Error processing PR: {str(e)}")
        raise e

class WorkerSettings:
    functions = [process_pull_request]
    redis_settings = RedisSettings(
        host=settings.redis_host, 
        port=settings.redis_port
    )