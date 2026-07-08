import base64
import time
import jwt
import requests
from github import Github, GithubException
from app.core.config import settings

def get_github_client(repo_name: str) -> Github:
    """
    Manually bypasses PyGithub's Auth engine to prevent Cloud Clock Skew 
    and Base64 padding corruption.
    """
    # 1. Decode Base64 (with safety padding in case Render stripped the trailing '=' signs)
    b64_key = settings.github_private_key.strip()
    b64_key += "=" * ((4 - len(b64_key) % 4) % 4)
    private_key = base64.b64decode(b64_key).decode("utf-8")

    # 2. Generate the App JWT manually (Subtract 60s to beat Render clock skew)
    payload = {
        "iat": int(time.time()) - 60,
        "exp": int(time.time()) + (10 * 60),
        "iss": str(settings.github_app_id)
    }
    app_jwt = jwt.encode(payload, private_key, algorithm="RS256")

    headers = {
        "Authorization": f"Bearer {app_jwt}",
        "Accept": "application/vnd.github.v3+json"
    }

    # 3. Ask GitHub for the Installation ID of this specific repository
    repo_url = f"https://api.github.com/repos/{repo_name}/installation"
    inst_response = requests.get(repo_url, headers=headers)
    
    if inst_response.status_code != 200:
        print(f"Failed to get installation ID: {inst_response.text}")
        raise ValueError("GitHub rejected the App JWT.")
        
    inst_id = inst_response.json()["id"]

    # 4. Generate the 1-hour Installation Access Token
    token_url = f"https://api.github.com/app/installations/{inst_id}/access_tokens"
    token_response = requests.post(token_url, headers=headers)
    
    if token_response.status_code != 201:
        print(f"Failed to generate access token: {token_response.text}")
        raise ValueError("GitHub rejected the Installation Token request.")
        
    access_token = token_response.json()["token"]

    # 5. Hand the pristine, fully-authorized token to PyGithub
    return Github(access_token)

def get_pull_request_files(repo_name: str, pr_number: int) -> list[dict]:
    """Fetches changed files, their diff patches, and raw file content."""
    g = get_github_client(repo_name)
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
    """Publishes a list of JSON comments to GitHub."""
    g = get_github_client(repo_name)
    repo = g.get_repo(repo_name)
    pr = repo.get_pull(pr_number)
    latest_commit = pr.get_commits().reversed[0]
    
    for comment_data in comments:
        line_num = comment_data.get("line")
        body = comment_data.get("comment")
        
        if not body:
            continue
            
        try:
            # THE FIX IS HERE: Changed commit_id= to commit=
            pr.create_review_comment(
                body=f"🤖 **MergeLens AI:**\n\n{body}",
                commit=latest_commit, 
                path=file_path,
                line=line_num
            )
            print(f"Published inline comment on {file_path}:{line_num}")
            
        except GithubException as e:
            print(f"Inline comment failed for {file_path}:{line_num}. Falling back to general comment.")
            pr.create_issue_comment(
                f"🤖 **MergeLens AI (File: `{file_path}`, Line: {line_num}):**\n\n{body}"
            )