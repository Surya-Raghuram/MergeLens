from fastapi import APIRouter, Depends, Request, HTTPException, status
from app.core.security import verify_github_signature
from app.models.github import GitHubWebhookPayload
import app.main as main_app # To access the global arq_pool safely

router = APIRouter(prefix="/webhooks", tags=["webhooks"])

@router.post("/github", dependencies=[Depends(verify_github_signature)])
async def github_webhook_receiver(payload: GitHubWebhookPayload, request: Request):
    """
    Receives and processes validated GitHub webhooks.
    """
    # We only care about PR events (opened or updated)
    event_type = request.headers.get("X-GitHub-Event")
    
    if event_type != "pull_request":
        return {"message": f"Ignored event type: {event_type}"}

    if not payload.pull_request:
        return {"message": "Ignored: No pull request data found"}

    # 'synchronize' means a new commit was pushed to the PR branch
    if payload.action not in ["opened", "synchronize"]:
        return {"message": f"Ignored PR action: {payload.action}"}

    repo_name = payload.repository.full_name
    pr_number = payload.pull_request.number

    if not main_app.arq_pool:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Task queue is not initialized"
        )

    # Push to Redis and return 200 OK immediately to satisfy GitHub's timeout rules
    job = await main_app.arq_pool.enqueue_job(
        'process_pull_request', 
        pr_number=pr_number, 
        repo_name=repo_name
    )

    return {
        "message": "PR processing initiated",
        "job_id": job.job_id,
        "repo": repo_name,
        "pr": pr_number
    }