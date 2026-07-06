from github import Github
from app.core.config import settings

def get_pull_request_files(repo_name: str, pr_number: int) -> list[dict]:
    """
    Fetches the list of files changed in a Pull Request and their patch diffs.
    """
    g = Github(settings.github_token)
    repo = g.get_repo(repo_name)
    pr = repo.get_pull(pr_number)
    
    changed_files = []
    for file in pr.get_files():
        changed_files.append({
            "filename": file.filename,
            "status": file.status,     # 'added', 'modified', 'removed'
            "patch": file.patch        # The actual code diff
        })
        
    return changed_files