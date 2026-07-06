import asyncio
from arq.connections import RedisSettings
from app.core.config import settings
from app.services.github_client import get_pull_request_files

async def process_pull_request(ctx: dict, pr_number: int, repo_name: str) -> str:
    """
    Background job to process a GitHub Pull Request.
    """
    print(f"[PR #{pr_number}] Starting analysis for repository: {repo_name}...")
    
    try:
        # 1. Fetch changed files from GitHub (Sync I/O wrapped in thread or executed directly)
        # In a high-throughput system, you'd use a specific async HTTP client, 
        # but PyGithub is sufficient and robust for this milestone.
        files = get_pull_request_files(repo_name, pr_number)
        
        print(f"[PR #{pr_number}] Found {len(files)} changed file(s).")
        for f in files:
            print(f" - {f['filename']} ({f['status']})")
        
        # Next Milestone: Pass these files to the C++ Analyzer
        
        # Next Milestone: Pass the analyzer output to LangGraph
        
        # Simulate processing time for now
        await asyncio.sleep(2)
        
        print(f"[PR #{pr_number}] Analysis complete.")
        return f"Successfully processed {repo_name} PR #{pr_number}"
        
    except Exception as e:
        print(f"[PR #{pr_number}] Error processing PR: {str(e)}")
        raise e

class WorkerSettings:
    functions = [process_pull_request]
    redis_settings = RedisSettings(
        host=settings.redis_host, 
        port=settings.redis_port
    )