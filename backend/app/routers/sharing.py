"""Sharing endpoints for file collaboration"""
from fastapi import APIRouter, HTTPException, status
from ..models.sharing import (
    ShareFileRequest,
    ShareFileResponse,
    RemoveShareRequest,
    RemoveShareResponse,
    ListSharesResponse,
    CollaboratorInfo,
)
from ..services.sharing_service import get_sharing_service
from ..services.supabase_service import get_supabase_service

router = APIRouter(prefix="/api/sharing", tags=["sharing"])


@router.post("/share", response_model=ShareFileResponse)
async def share_file(request: ShareFileRequest):
    """
    Share a file or folder with another user
    
    This endpoint:
    1. Gets or creates the file record in the database
    2. Looks up the recipient user by email
    3. Creates a share record in the database
    4. For folders, recursively shares all contents
    
    Args:
        request: Share request with file info and recipient
        
    Returns:
        Success response with share ID
    """
    try:
        sharing_service = get_sharing_service()
        supabase_service = get_supabase_service()
        
        # Get owner user from database
        owner_response = supabase_service.client.table("users").select("id").eq(
            "google_sub", request.user_id
        ).execute()
        
        if not owner_response.data or len(owner_response.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Owner user not found"
            )
        
        owner_db_id = owner_response.data[0]["id"]
        
        # Get or create file record
        file_record = await sharing_service.get_or_create_file_record(
            user_id=owner_db_id,
            drive_file_id=request.drive_file_id,
            name=request.file_name,
            mime_type=request.mime_type,
            size_bytes=request.size_bytes,
            is_folder=request.is_folder,
        )
        
        file_db_id = file_record["id"]
        
        # Look up recipient user by email
        recipient_user = await sharing_service.get_user_by_email(request.shared_with_email)
        recipient_user_id = recipient_user["id"] if recipient_user else None
        
        # Validate permission
        if request.permission not in ['viewer', 'editor']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Permission must be 'viewer' or 'editor'"
            )
        
        # Share the file or folder
        if request.is_folder:
            # Recursively share folder and contents
            files_shared = await sharing_service.share_folder_recursively(
                folder_id=file_db_id,
                owner_id=owner_db_id,
                shared_with_email=request.shared_with_email,
                permission=request.permission,
                shared_with_user_id=recipient_user_id,
            )
            
            return ShareFileResponse(
                success=True,
                message=f"Folder shared successfully ({files_shared} items)",
                files_shared=files_shared,
            )
        else:
            # Share single file
            share_record = await sharing_service.create_share(
                file_id=file_db_id,
                owner_id=owner_db_id,
                shared_with_email=request.shared_with_email,
                permission=request.permission,
                shared_with_user_id=recipient_user_id,
            )
            
            return ShareFileResponse(
                success=True,
                message="File shared successfully",
                share_id=share_record["id"],
                files_shared=1,
            )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to share file: {str(e)}"
        )


@router.post("/remove", response_model=RemoveShareResponse)
async def remove_share(request: RemoveShareRequest):
    """
    Remove a share (revoke access)
    
    Args:
        request: Remove share request with file info and recipient
        
    Returns:
        Success response
    """
    try:
        sharing_service = get_sharing_service()
        supabase_service = get_supabase_service()
        
        # Get owner user from database
        owner_response = supabase_service.client.table("users").select("id").eq(
            "google_sub", request.user_id
        ).execute()
        
        if not owner_response.data or len(owner_response.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Owner user not found"
            )
        
        owner_db_id = owner_response.data[0]["id"]
        
        # Get file record
        file_response = supabase_service.client.table("files").select("id").eq(
            "user_id", owner_db_id
        ).eq("drive_file_id", request.drive_file_id).execute()
        
        if not file_response.data or len(file_response.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File not found"
            )
        
        file_db_id = file_response.data[0]["id"]
        
        # Remove the share
        await sharing_service.remove_share(
            file_id=file_db_id,
            shared_with_email=request.shared_with_email,
        )
        
        return RemoveShareResponse(
            success=True,
            message="Share removed successfully"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to remove share: {str(e)}"
        )


@router.get("/list/{user_id}/{drive_file_id}", response_model=ListSharesResponse)
async def list_shares(user_id: str, drive_file_id: str):
    """
    List all collaborators for a file
    
    Args:
        user_id: Google sub claim of the owner
        drive_file_id: Google Drive file ID
        
    Returns:
        List of collaborators with their permissions
    """
    try:
        sharing_service = get_sharing_service()
        supabase_service = get_supabase_service()
        
        # Get owner user from database
        owner_response = supabase_service.client.table("users").select("id").eq(
            "google_sub", user_id
        ).execute()
        
        if not owner_response.data or len(owner_response.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Owner user not found"
            )
        
        owner_db_id = owner_response.data[0]["id"]
        
        # Get file record
        file_response = supabase_service.client.table("files").select("id").eq(
            "user_id", owner_db_id
        ).eq("drive_file_id", drive_file_id).execute()
        
        if not file_response.data or len(file_response.data) == 0:
            # File not in database yet, return empty list
            return ListSharesResponse(
                success=True,
                collaborators=[]
            )
        
        file_db_id = file_response.data[0]["id"]
        
        # Get all shares for this file
        shares = await sharing_service.get_file_shares(file_db_id)
        
        # Convert to collaborator info
        collaborators = []
        for share in shares:
            collaborator = CollaboratorInfo(
                email=share["shared_with_email"],
                permission=share["permission"],
                shared_at=share["created_at"],
            )
            
            # Add user info if available
            if share.get("shared_with_user"):
                user_info = share["shared_with_user"]
                collaborator.name = user_info.get("name")
                collaborator.picture_url = user_info.get("picture_url")
            
            collaborators.append(collaborator)
        
        return ListSharesResponse(
            success=True,
            collaborators=collaborators
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list shares: {str(e)}"
        )


@router.get("/shared-with-me/{user_id}")
async def list_shared_with_me(user_id: str):
    """
    List all files shared with the current user
    
    Args:
        user_id: Google sub claim of the current user
        
    Returns:
        List of files shared with the user
    """
    try:
        supabase_service = get_supabase_service()
        
        # Get user from database
        user_response = supabase_service.client.table("users").select("id, email").eq(
            "google_sub", user_id
        ).execute()
        
        if not user_response.data or len(user_response.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User not found. Please sign in first to create your account. (Google sub: {user_id})"
            )
        
        user_db_id = user_response.data[0]["id"]
        user_email = user_response.data[0]["email"]
        
        # Get all shares where user is the recipient (by user_id or email)
        shares_response = supabase_service.client.table("shares").select(
            "*, file:file_id(id, drive_file_id, name, mime_type, size_bytes, is_folder), owner:owner_id(name, email, picture_url)"
        ).or_(
            f"shared_with_user_id.eq.{user_db_id},shared_with_email.eq.{user_email}"
        ).eq("is_public", False).execute()
        
        shared_files = []
        for share in shares_response.data if shares_response.data else []:
            file_info = share.get("file")
            owner_info = share.get("owner")
            
            if file_info:
                shared_files.append({
                    "drive_file_id": file_info["drive_file_id"],
                    "name": file_info["name"],
                    "mime_type": file_info["mime_type"],
                    "size_bytes": file_info.get("size_bytes"),
                    "is_folder": file_info.get("is_folder", False),
                    "permission": share["permission"],
                    "owner_name": owner_info.get("name") if owner_info else None,
                    "owner_email": owner_info.get("email") if owner_info else None,
                    "shared_at": share["created_at"],
                })
        
        return {
            "success": True,
            "shared_files": shared_files
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list shared files: {str(e)}"
        )
