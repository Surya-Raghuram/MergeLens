from pydantic import BaseModel
from typing import Optional

class RepositoryInfo(BaseModel):
    full_name: str
    name: str

class PullRequestInfo(BaseModel):
    number: int
    state: str
    title: str

class GitHubWebhookPayload(BaseModel):
    action: str
    pull_request: Optional[PullRequestInfo] = None
    repository: RepositoryInfo