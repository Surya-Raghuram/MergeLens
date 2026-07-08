from github import Github, Auth, GithubException
from app.core.config import settings

from github import Github, Auth, GithubException
from app.core.config import settings

import re # <-- NEW: Required for the bulletproof string cleaner
from github import Github, Auth, GithubException
from app.core.config import settings

def get_github_client(repo_name: str) -> Github:
    """
    Dynamically generates a 1-hour Installation Access Token for the requested repository.
    """
    raw_key = settings.github_private_key
    
    # --- BULLETPROOF PEM RECONSTRUCTOR ---
    # 1. Strip the header and footer temporarily
    core_key = re.sub(r'-----BEGIN RSA PRIVATE KEY-----', '', raw_key)
    core_key = re.sub(r'-----END RSA PRIVATE KEY-----', '', core_key)
    
    # 2. Remove absolutely all whitespace, literal '\n' text, and hidden characters
    core_key = re.sub(r'\s+|\\n', '', core_key)
    
    # 3. Rebuild the key with perfect, strict PEM formatting
    private_key = f"-----BEGIN RSA PRIVATE KEY-----\n{core_key}\n-----END RSA PRIVATE KEY-----"
    # -------------------------------------
    
    # Authenticate as the base GitHub App
    app_auth = Auth.AppAuth(settings.github_app_id, private_key)
    app_client = Github(auth=app_auth)
    
    # Get the specific installation ID for this repository
    installation = app_client.get_repo(repo_name).get_installation()
    
    # Create the Installation Auth object
    inst_auth = Auth.AppInstallationAuth(app_auth, installation.id)
    
    # Return the client authenticated as the installation bot
    return Github(auth=inst_auth)

def get_pull_request_files(repo_name: str, pr_number: int) -> list[dict]:
    """Fetches changed files, their diff patches, and raw file content."""
    g = get_github_client(repo_name) # <-- Now requires repo_name to generate token
    repo = g.get_repo(repo_name)
    pr = repo.get_pull(pr_number)
    
    changed_files = []
    for file in pr.get_files():
        if file.status in ["added", "modified"]:
            try:
                file_content = repo.get_contents(file.filename, ref=pr.head.sha)
                decoded_content = file_content.decoded_content.decode("utf-8")
                
                changed_files.append({
                    "filename": file.filename,
                    "status": file.status,
                    "patch": file.patch,
                    "content": decoded_content
                })
            except Exception as e:
                print(f"Skipping content fetch for {file.filename}: {e}")
                
    return changed_files

def publish_review_comments(repo_name: str, pr_number: int, file_path: str, comments: list):
    """
    Publishes a list of JSON comments to GitHub.
    """
    g = get_github_client(repo_name) # <-- Now requires repo_name to generate token
    repo = g.get_repo(repo_name)
    pr = repo.get_pull(pr_number)
    latest_commit = pr.get_commits().reversed[0]
    
    for comment_data in comments:
        line_num = comment_data.get("line")
        body = comment_data.get("comment")
        
        if not body:
            continue
            
        try:
            pr.create_review_comment(
                body=f"🤖 **MergeLens AI:**\n\n{body}",
                commit_id=latest_commit,
                path=file_path,
                line=line_num
            )
            print(f"Published inline comment on {file_path}:{line_num}")
            
        except GithubException as e:
            print(f"Inline comment failed for {file_path}:{line_num}. Falling back to general comment.")
            pr.create_issue_comment(
                f"🤖 **MergeLens AI (File: `{file_path}`, Line: {line_num}):**\n\n{body}"
            )