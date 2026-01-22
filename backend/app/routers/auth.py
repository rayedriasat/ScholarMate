"""Authentication endpoints for OAuth flow"""
import logging
import os
import httpx
import json
import base64
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, HTTPException, status, Request, Query
from fastapi.responses import RedirectResponse
from ..models.auth import StoreTokensRequest, StoreTokensResponse, RefreshTokenResponse, SessionResponse
from ..services.encryption_service import get_encryption_service
from ..services.supabase_service import get_supabase_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/auth", tags=["authentication"])

# Environment variables
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET")
# Determine the backend URL for the redirect URI
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8000")
REDIRECT_URI = f"{BACKEND_URL}/api/auth/google/callback"

# Frontend URLs
FRONTEND_WEB_URL = os.getenv("FRONTEND_WEB_URL", "http://localhost:8080")
ANDROID_SCHEME = "myapp://auth-success"
WINDOWS_LOOPBACK_URL = "http://localhost:3000"


@router.get("/google")
async def google_login(platform: str = Query(..., regex="^(android|web|windows)$")):
    """
    Initiate Google OAuth2 flow
    
    Args:
        platform: 'android', 'web', or 'windows' to determine redirect behavior
    """
    if not GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=500, detail="Google Client ID not configured")

    # Scopes required
    scopes = [
        "openid",
        "email",
        "profile",
        "https://www.googleapis.com/auth/drive"
    ]
    
    # State parameter to pass platform info through the OAuth flow
    state = platform
    
    # Construct authorization URL
    auth_url = "https://accounts.google.com/o/oauth2/v2/auth"
    params = {
        "client_id": GOOGLE_CLIENT_ID,
        "redirect_uri": REDIRECT_URI,
        "response_type": "code",
        "scope": " ".join(scopes),
        "access_type": "offline",  # Request refresh token
        "include_granted_scopes": "true",
        "state": state,
        "prompt": "consent"  # Force consent to ensure we get refresh token
    }
    
    url = httpx.URL(auth_url).copy_with(params=params)
    return RedirectResponse(url=str(url))


@router.get("/google/callback")
async def google_callback(code: str, state: str, error: Optional[str] = None):
    """
    Handle Google OAuth2 callback
    """
    if error:
        raise HTTPException(status_code=400, detail=f"OAuth error: {error}")
        
    if not GOOGLE_CLIENT_ID or not GOOGLE_CLIENT_SECRET:
        raise HTTPException(status_code=500, detail="Google credentials not configured")

    try:
        # Exchange code for tokens
        token_url = "https://oauth2.googleapis.com/token"
        async with httpx.AsyncClient() as client:
            token_response = await client.post(token_url, data={
                "client_id": GOOGLE_CLIENT_ID,
                "client_secret": GOOGLE_CLIENT_SECRET,
                "code": code,
                "grant_type": "authorization_code",
                "redirect_uri": REDIRECT_URI,
            })
            
            if token_response.status_code != 200:
                logger.error(f"Token exchange failed: {token_response.text}")
                raise HTTPException(status_code=400, detail="Failed to retrieve tokens")
                
            token_data = token_response.json()
            
            # Get user info
            user_info_response = await client.get(
                "https://www.googleapis.com/oauth2/v3/userinfo",
                headers={"Authorization": f"Bearer {token_data['access_token']}"}
            )
            
            if user_info_response.status_code != 200:
                raise HTTPException(status_code=400, detail="Failed to retrieve user info")
                
            user_info = user_info_response.json()

        # Store in Supabase
        supabase_service = get_supabase_service()
        encryption_service = get_encryption_service()
        
        # Get or create user
        user = await supabase_service.get_or_create_user(
            google_sub=user_info["sub"],
            email=user_info["email"],
            name=user_info.get("name"),
            picture_url=user_info.get("picture")
        )
        
        db_user_id = user["id"]
        
        # Store encrypted access token
        encrypted_access_token = encryption_service.encrypt(token_data["access_token"])
        await supabase_service.store_encrypted_token(
            user_id=db_user_id,
            token_type="access_token",
            encrypted_token=encrypted_access_token
        )
        
        # Store encrypted refresh token (if present)
        if "refresh_token" in token_data:
            encrypted_refresh_token = encryption_service.encrypt(token_data["refresh_token"])
            await supabase_service.store_encrypted_token(
                user_id=db_user_id,
                token_type="refresh_token",
                encrypted_token=encrypted_refresh_token
            )
        
        # Prepare session data to return to client via redirect
        # We encrypt this payload so it can be safely passed in the URL
        session_payload = {
            "access_token": token_data["access_token"],
            "expires_in": token_data.get("expires_in", 3600),
            "user_id": user_info["sub"],
            "email": user_info["email"],
            "name": user_info.get("name"),
            "picture_url": user_info.get("picture"),
            "created_at": datetime.utcnow().timestamp()
        }
        
        payload_json = json.dumps(session_payload)
        encrypted_session = encryption_service.encrypt(payload_json)
        
        # Determine redirect URL based on platform (state)
        platform = state
        if platform == "android":
            redirect_url = f"{ANDROID_SCHEME}?code={encrypted_session}"
        elif platform == "windows":
            # Redirect to local loopback server running on Windows client
            redirect_url = f"{WINDOWS_LOOPBACK_URL}?code={encrypted_session}"
        else: # web
            redirect_url = f"{FRONTEND_WEB_URL}/auth-callback?code={encrypted_session}"
            
        return RedirectResponse(url=redirect_url)

    except Exception as e:
        logger.error(f"Callback error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Authentication failed: {str(e)}")


@router.get("/session", response_model=SessionResponse)
async def get_session(code: str):
    """
    Exchange the temporary session code for actual session data
    """
    try:
        encryption_service = get_encryption_service()
        
        # Decrypt the session data
        decrypted_json = encryption_service.decrypt(code)
        session_data = json.loads(decrypted_json)
        
        # Validate expiry (code should be short-lived, e.g., 5 mins)
        created_at = datetime.fromtimestamp(session_data["created_at"])
        if datetime.utcnow() - created_at > timedelta(minutes=5):
            raise HTTPException(status_code=400, detail="Session code expired")
            
        # Calculate expiry time string
        expires_in = session_data.get("expires_in", 3600)
        token_expiry = datetime.utcnow() + timedelta(seconds=expires_in)
        
        return SessionResponse(
            access_token=session_data["access_token"],
            token_expiry=token_expiry.isoformat(),
            user_id=session_data["user_id"],
            email=session_data["email"],
            name=session_data.get("name"),
            picture_url=session_data.get("picture_url")
        )
        
    except Exception as e:
        logger.error(f"Session retrieval error: {str(e)}")
        raise HTTPException(status_code=400, detail="Invalid session code")


# Keep existing endpoints for Windows/Legacy support
@router.post("/store-tokens", response_model=StoreTokensResponse)
async def store_tokens(request: StoreTokensRequest):
    """Store encrypted OAuth tokens for a user (Client-side flow)"""
    try:
        encryption_service = get_encryption_service()
        supabase_service = get_supabase_service()
        
        user = await supabase_service.get_or_create_user(
            google_sub=request.user_id,
            email=request.email,
            name=request.name,
            picture_url=request.picture_url
        )
        
        db_user_id = user["id"]
        
        encrypted_access_token = encryption_service.encrypt(request.access_token)
        await supabase_service.store_encrypted_token(
            user_id=db_user_id,
            token_type="access_token",
            encrypted_token=encrypted_access_token
        )
        
        if request.refresh_token and request.refresh_token.strip() != "":
            encrypted_refresh_token = encryption_service.encrypt(request.refresh_token)
            await supabase_service.store_encrypted_token(
                user_id=db_user_id,
                token_type="refresh_token",
                encrypted_token=encrypted_refresh_token
            )
        else:
            await supabase_service.store_encrypted_token(
                user_id=db_user_id,
                token_type="refresh_token",
                encrypted_token="CLIENT_MANAGED"
            )
        
        if request.id_token and request.id_token.strip() != "":
            encrypted_id_token = encryption_service.encrypt(request.id_token)
            await supabase_service.store_encrypted_token(
                user_id=db_user_id,
                token_type="id_token",
                encrypted_token=encrypted_id_token
            )
        
        return StoreTokensResponse(
            success=True,
            message="Tokens stored successfully",
            user_id=db_user_id
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to store tokens: {str(e)}"
        )

@router.delete("/tokens")
async def delete_tokens(user_id: str):
    """Delete all tokens for a user"""
    try:
        supabase_service = get_supabase_service()
        response = supabase_service.client.table("users").select("id").eq("google_sub", user_id).execute()
        
        if not response.data or len(response.data) == 0:
            raise HTTPException(status_code=404, detail="User not found")
        
        db_user_id = response.data[0]["id"]
        await supabase_service.delete_user_tokens(db_user_id)
        
        return {"success": True, "message": "Tokens deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete tokens: {str(e)}")
