"""Authentication endpoints

Note: Token management is handled entirely on the frontend by google_sign_in_all_platforms.
The backend only stores user metadata for features like tags, indexing, and AI chat.
"""
import logging
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from ..services.supabase_service import get_supabase_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/auth", tags=["authentication"])


class UserInfoRequest(BaseModel):
    """Request to store/update user info"""
    user_id: str  # Google sub claim
    email: str
    name: str | None = None
    picture_url: str | None = None


class UserInfoResponse(BaseModel):
    """Response with user info"""
    success: bool
    message: str
    db_user_id: str | None = None


@router.post("/user-info", response_model=UserInfoResponse)
async def store_user_info(request: UserInfoRequest):
    """
    Store or update user information in the database.
    
    This is called when a user signs in to ensure their profile exists
    in the database for features like tags, file metadata, etc.
    
    Note: This does NOT store OAuth tokens - those are managed by
    google_sign_in_all_platforms on the frontend.
    """
    try:
        supabase_service = get_supabase_service()
        
        # Get or create user
        user = await supabase_service.get_or_create_user(
            google_sub=request.user_id,
            email=request.email,
            name=request.name,
            picture_url=request.picture_url
        )
        
        return UserInfoResponse(
            success=True,
            message="User info stored successfully",
            db_user_id=user["id"]
        )
        
    except Exception as e:
        logger.error(f"Failed to store user info: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to store user info: {str(e)}"
        )


@router.get("/user/{google_sub}")
async def get_user(google_sub: str):
    """
    Get user information by Google sub claim.
    """
    try:
        supabase_service = get_supabase_service()
        
        response = supabase_service.client.table("users").select("*").eq("google_sub", google_sub).execute()
        
        if not response.data or len(response.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        user = response.data[0]
        return {
            "id": user["id"],
            "google_sub": user["google_sub"],
            "email": user["email"],
            "name": user.get("name"),
            "picture_url": user.get("picture_url"),
            "created_at": user.get("created_at"),
            "updated_at": user.get("updated_at")
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get user: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user: {str(e)}"
        )


# Legacy endpoints for backward compatibility
# These can be removed in a future version

@router.post("/store-tokens")
async def store_tokens_legacy(request: dict):
    """
    Legacy endpoint - tokens are now managed on frontend.
    This just stores user info for backward compatibility.
    """
    try:
        supabase_service = get_supabase_service()
        
        user = await supabase_service.get_or_create_user(
            google_sub=request.get("user_id", ""),
            email=request.get("email", ""),
            name=request.get("name"),
            picture_url=request.get("picture_url")
        )
        
        return {
            "success": True,
            "message": "User info stored (tokens managed on frontend)",
            "user_id": user["id"]
        }
        
    except Exception as e:
        logger.error(f"Legacy store-tokens failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/refresh-token")
async def refresh_token_legacy(user_id: str):
    """
    Legacy endpoint - token refresh is now handled on frontend.
    """
    return {
        "access_token": None,
        "message": "Token refresh is now handled on frontend by google_sign_in_all_platforms"
    }


@router.delete("/tokens")
async def delete_tokens_legacy(user_id: str):
    """
    Legacy endpoint - sign out is now handled on frontend.
    """
    return {
        "success": True,
        "message": "Sign out is now handled on frontend"
    }
