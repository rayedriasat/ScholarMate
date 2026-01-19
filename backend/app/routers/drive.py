"""Drive API endpoints"""
import logging
import os
import httpx
from fastapi import APIRouter, HTTPException, status, Query
from ..services.encryption_service import get_encryption_service
from ..services.supabase_service import get_supabase_service
from ..models.auth import RefreshTokenResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/drive", tags=["drive"])

GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET")

@router.get("/access-token", response_model=RefreshTokenResponse)
async def get_access_token(user_id: str = Query(...)):
    """
    Get a fresh access token for Google Drive operations using the stored refresh token.
    
    Args:
        user_id: The Google Subject ID (user ID)
    """
    if not GOOGLE_CLIENT_ID or not GOOGLE_CLIENT_SECRET:
        raise HTTPException(status_code=500, detail="Google credentials not configured")

    try:
        supabase_service = get_supabase_service()
        encryption_service = get_encryption_service()
        
        # 1. Get user by Google Sub
        user = await supabase_service.get_user_by_google_sub(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        db_user_id = user["id"]
        
        # 2. Get encrypted refresh token
        encrypted_refresh_token = await supabase_service.get_encrypted_token(
            user_id=db_user_id,
            token_type="refresh_token"
        )
        
        if not encrypted_refresh_token:
            raise HTTPException(status_code=401, detail="No refresh token found. Please sign in again.")
            
        if encrypted_refresh_token == "CLIENT_MANAGED":
             raise HTTPException(status_code=400, detail="This platform uses client-side token management.")

        # 3. Decrypt refresh token
        refresh_token = encryption_service.decrypt(encrypted_refresh_token)
        
        # 4. Exchange refresh token for new access token
        token_url = "https://oauth2.googleapis.com/token"
        async with httpx.AsyncClient() as client:
            response = await client.post(token_url, data={
                "client_id": GOOGLE_CLIENT_ID,
                "client_secret": GOOGLE_CLIENT_SECRET,
                "refresh_token": refresh_token,
                "grant_type": "refresh_token"
            })
            
            if response.status_code != 200:
                logger.error(f"Token refresh failed: {response.text}")
                # If refresh fails (e.g., revoked), we should probably delete the token?
                # For now, just error out.
                raise HTTPException(status_code=401, detail="Failed to refresh token")
                
            token_data = response.json()
            new_access_token = token_data["access_token"]
            
            # Optionally update the access token in DB
            encrypted_new_access_token = encryption_service.encrypt(new_access_token)
            await supabase_service.store_encrypted_token(
                user_id=db_user_id,
                token_type="access_token",
                encrypted_token=encrypted_new_access_token
            )
            
            return RefreshTokenResponse(
                access_token=new_access_token,
                message="Token refreshed successfully"
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting access token: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")
