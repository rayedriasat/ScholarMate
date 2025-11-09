"""Authentication endpoints"""
from fastapi import APIRouter, HTTPException, status
from ..models.auth import StoreTokensRequest, StoreTokensResponse, RefreshTokenResponse
from ..services.encryption_service import get_encryption_service
from ..services.supabase_service import get_supabase_service

router = APIRouter(prefix="/api/auth", tags=["authentication"])


@router.post("/store-tokens", response_model=StoreTokensResponse)
async def store_tokens(request: StoreTokensRequest):
    """
    Store encrypted OAuth tokens for a user
    
    This endpoint:
    1. Creates or updates the user record in the database
    2. Encrypts the OAuth tokens
    3. Stores the encrypted tokens in the database
    
    Args:
        request: Token storage request with user info and tokens
        
    Returns:
        Success response with database user ID
    """
    try:
        encryption_service = get_encryption_service()
        supabase_service = get_supabase_service()
        
        # Get or create user
        user = await supabase_service.get_or_create_user(
            google_sub=request.user_id,
            email=request.email,
            name=request.name,
            picture_url=request.picture_url
        )
        
        db_user_id = user["id"]
        
        # Validate and encrypt access token
        if not request.access_token or request.access_token.strip() == "":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Access token is required and cannot be empty"
            )
        
        encrypted_access_token = encryption_service.encrypt(request.access_token)
        await supabase_service.store_encrypted_token(
            user_id=db_user_id,
            token_type="access_token",
            encrypted_token=encrypted_access_token
        )
        
        # Encrypt and store refresh token if provided
        # Note: google_sign_in v7+ doesn't expose refresh tokens directly
        # They're managed internally by the plugin
        if request.refresh_token and request.refresh_token.strip() != "":
            encrypted_refresh_token = encryption_service.encrypt(request.refresh_token)
            await supabase_service.store_encrypted_token(
                user_id=db_user_id,
                token_type="refresh_token",
                encrypted_token=encrypted_refresh_token
            )
        else:
            # Store a placeholder to indicate token refresh is handled client-side
            logger.info(f"No refresh token provided for user {db_user_id} - using client-side refresh")
            await supabase_service.store_encrypted_token(
                user_id=db_user_id,
                token_type="refresh_token",
                encrypted_token=encryption_service.encrypt("CLIENT_MANAGED")
            )
        
        # Encrypt and store ID token if provided
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


@router.get("/refresh-token", response_model=RefreshTokenResponse)
async def refresh_token(user_id: str):
    """
    Get decrypted access token for a user
    
    Note: In a production system, you would implement actual token refresh logic
    with Google OAuth. For now, this returns the stored access token.
    
    Args:
        user_id: Google sub claim (user ID)
        
    Returns:
        Decrypted access token
    """
    try:
        encryption_service = get_encryption_service()
        supabase_service = get_supabase_service()
        
        # Get user from database
        response = supabase_service.client.table("users").select("id").eq("google_sub", user_id).execute()
        
        if not response.data or len(response.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        db_user_id = response.data[0]["id"]
        
        # Get encrypted access token
        encrypted_token = await supabase_service.get_encrypted_token(
            user_id=db_user_id,
            token_type="access_token"
        )
        
        if not encrypted_token:
            return RefreshTokenResponse(
                access_token=None,
                message="No access token found for user"
            )
        
        # Decrypt token
        access_token = encryption_service.decrypt(encrypted_token)
        
        return RefreshTokenResponse(
            access_token=access_token,
            message="Token retrieved successfully"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to refresh token: {str(e)}"
        )


@router.delete("/tokens")
async def delete_tokens(user_id: str):
    """
    Delete all tokens for a user (sign out)
    
    Args:
        user_id: Google sub claim (user ID)
        
    Returns:
        Success message
    """
    try:
        supabase_service = get_supabase_service()
        
        # Get user from database
        response = supabase_service.client.table("users").select("id").eq("google_sub", user_id).execute()
        
        if not response.data or len(response.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        db_user_id = response.data[0]["id"]
        
        # Delete all tokens
        await supabase_service.delete_user_tokens(db_user_id)
        
        return {"success": True, "message": "Tokens deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete tokens: {str(e)}"
        )
