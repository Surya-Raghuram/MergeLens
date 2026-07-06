from github import Github, GithubException
from app.core.config import settings

def get_github_client() -> Github:
    return Github(settings.github_token)

def get_pull_request_files(repo_name: str, pr_number: int) -> list[dict]:
    """Fetches changed files, their diff patches, and raw file content."""
    g = get_github_client()
    repo = g.get_repo(repo_name)
    pr = repo.get_pull(pr_number)
    
    changed_files = []
    for file in pr.get_files():
        # Only process added or modified files (ignore deleted ones)
        if file.status in ["added", "modified"]:
            try:
                # Fetch the full file content from the PR's branch
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
    Attempts inline comments first, falls back to general PR comments on API rejection.
    """
    g = get_github_client()
    repo = g.get_repo(repo_name)
    pr = repo.get_pull(pr_number)
    latest_commit = pr.get_commits().reversed[0] # Get the most recent commit in the PR
    
    for comment_data in comments:
        line_num = comment_data.get("line")
        body = comment_data.get("comment")
        
        if not body:
            continue
            
        try:
            # Attempt to create an inline review comment on the specific line
            pr.create_review_comment(
                body=f"🤖 **MergeLens AI:**\n\n{body}",
                commit_id=latest_commit,
                path=file_path,
                line=line_num
            )
            print(f"Published inline comment on {file_path}:{line_num}")
            
        except GithubException as e:
            # GitHub blocks inline comments if the line isn't part of the direct diff.
            # Fallback: Post as a general PR comment.
            print(f"Inline comment failed for {file_path}:{line_num}. Falling back to general comment.")
            pr.create_issue_comment(
                f" **MergeLens AI (File: `{file_path}`, Line: {line_num}):**\n\n{body}"
            )