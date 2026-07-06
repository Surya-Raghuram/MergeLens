import asyncio
import os
from app.analyzer.graph import review_brain

async def run_mock_review():
    # Mock data modeling a real code adjustment in main.py
    mock_input = {
        "file_path": "/app/backend/app/main.py",
        "patch": """
@@ -32,4 +32,7 @@ def health_check():
 def health_check():
-    return {"status": "ok"}
+    # Modified health check endpoint logic
+    if not os.path.exists('/app/backend/app/main.py'):
+        return {"status": "degraded", "error": "Core files missing"}
+    return {"status": "healthy"}
        """,
        "language": "",
        "cpp_structure": None,
        "structural_intent": None,
        "review_comments": [],
        "next_step": ""
    }
    
    print("🧠 Kicking off LangGraph Analysis Brain...")
    final_state = await review_brain.ainvoke(mock_input)
    
    print("\n--- [1] Structural Intent Identified ---")
    print(final_state.get("structural_intent"))
    
    print("\n--- [2] Resulting Line Comments Generated ---")
    import json
    print(json.dumps(final_state.get("review_comments"), indent=2))

# Change this at the very bottom of backend/app/test_graph.py
if __name__ == "__main__":
    if "GOOGLE_API_KEY" not in os.environ:
        print("❌ Error: Please set the GOOGLE_API_KEY environment variable before running.")
    else:
        asyncio.run(run_mock_review())