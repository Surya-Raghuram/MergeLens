import hmac
import hashlib
from fastapi import Request, HTTPException, status
from app.core.config import settings

async def verify_github_signature(request: Request):
    """
    FastAPI Dependency to verify the GitHub webhook signature using HMAC SHA-256.
    """
    signature_header = request.headers.get("X-Hub-Signature-256")
    if not signature_header:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing X-Hub-Signature-256 header"
        )

    # GitHub's header looks like "sha256=123456..."
    try:
        _, signature = signature_header.split("=")
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid signature format"
        )

    # We must read the raw body for HMAC generation
    payload = await request.body()
    mac = hmac.new(
        settings.github_webhook_secret.encode("utf-8"),
        msg=payload,
        digestmod=hashlib.sha256
    )
    
    expected_signature = mac.hexdigest()
    
    if not hmac.compare_digest(expected_signature, signature):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Signatures do not match"
        )