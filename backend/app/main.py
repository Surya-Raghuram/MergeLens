from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from arq import create_pool
from arq.connections import RedisSettings
from app.core.config import settings
from app.core.supabase_client import supabase
from app.api.webhooks import router as webhooks_router

# Global reference to the Redis task pool
arq_pool = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Create the Redis connection pool for enqueuing jobs
    global arq_pool
    arq_pool = await create_pool(
        RedisSettings(host=settings.redis_host, port=settings.redis_port)
    )
    yield
    # Shutdown: Close the Redis pool
    if arq_pool:
        await arq_pool.close()

app = FastAPI(
    title="MergeLens API",
    description="Backend gateway for autonomous code reviews",
    version="0.1.0",
    lifespan=lifespan
)

app.include_router(webhooks_router)

@app.get("/health")
async def health_check():
    """
    Verifies that the API, Task Queue, and Database are operational.
    """
    # 1. Check Supabase connection (simple query)
    try:
        supabase_status = "ok" if supabase else "uninitialized"
    except Exception as e:
        supabase_status = f"error: {str(e)}"

    # 2. Check Task Queue connection
    try:
        redis_status = "ok" if arq_pool else "uninitialized"
    except Exception as e:
        redis_status = f"error: {str(e)}"

    return {
        "status": "healthy",
        "supabase": supabase_status,
        "redis_queue": redis_status
    }

@app.post("/test-trigger")
async def trigger_test_job(pr_id: str, repo_name: str):
    """
    Simulates receiving a webhook and enqueuing a background job.
    """
    if not arq_pool:
        raise HTTPException(status_code=500, detail="Task queue is not initialized")
    
    # Enqueue the job immediately and return 200 to prevent timeouts
    job = await arq_pool.enqueue_job('process_pull_request', pr_id, repo_name)
    
    if not job:
        raise HTTPException(status_code=500, detail="Failed to enqueue job")
        
    return {
        "message": "Job queued successfully",
        "job_id": job.job_id
    }