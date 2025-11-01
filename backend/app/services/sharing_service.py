"""Sharing service for managing file permissions and collaboration"""
from typing import List, Dict, Any, Optional
from datetime import datetime
from .supabase_service import get_supabase_service


class SharingService:
    """Service for managing file sharing and permissions"""
    
    def __init__(self):
        """Initialize sharing service"""
        self.supabase = get_supabase_service()
    
    async def create_share(
        self,
        file_id: str,
        owner_id: str,
        shared_with_email: str,
        permission: str,
        shared_with_user_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Create a new share record
        
        Args:
            file_id: UUID of the file being shared
            owner_id: UUID of the file owner
            shared_with_email: Email of the person being shared with
            permission: 'viewer' or 'editor'
            shared_with_user_id: UUID of the user being shared with (if they have an account)
            
        Returns:
            Share record from database
        """
        # Check if share already exists
        existing = self.supabase.client.table("shares").select("*").eq(
            "file_id", file_id
        ).eq("shared_with_email", shared_with_email).execute()
        
        if existing.data and len(existing.data) > 0:
            # Update existing share
            share_id = existing.data[0]["id"]
            update_data = {
                "permission": permission,
                "updated_at": datetime.utcnow().isoformat()
            }
            if shared_with_user_id:
                update_data["shared_with_user_id"] = shared_with_user_id
            
            response = self.supabase.client.table("shares").update(
                update_data
            ).eq("id", share_id).execute()
            return response.data[0]
        else:
            # Create new share
            share_data = {
                "file_id": file_id,
                "owner_id": owner_id,
                "shared_with_email": shared_with_email,
                "permission": permission,
                "is_public": False,
            }
            if shared_with_user_id:
                share_data["shared_with_user_id"] = shared_with_user_id
            
            response = self.supabase.client.table("shares").insert(share_data).execute()
            return response.data[0]
    
    async def get_file_shares(self, file_id: str) -> List[Dict[str, Any]]:
        """
        Get all shares for a file
        
        Args:
            file_id: UUID of the file
            
        Returns:
            List of share records
        """
        response = self.supabase.client.table("shares").select(
            "*, shared_with_user:shared_with_user_id(name, email, picture_url)"
        ).eq("file_id", file_id).eq("is_public", False).execute()
        
        return response.data if response.data else []
    
    async def remove_share(self, file_id: str, shared_with_email: str) -> None:
        """
        Remove a share
        
        Args:
            file_id: UUID of the file
            shared_with_email: Email of the person to remove
        """
        self.supabase.client.table("shares").delete().eq(
            "file_id", file_id
        ).eq("shared_with_email", shared_with_email).execute()
    
    async def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """
        Get user by email
        
        Args:
            email: User email
            
        Returns:
            User record or None if not found
        """
        response = self.supabase.client.table("users").select("*").eq("email", email).execute()
        
        if response.data and len(response.data) > 0:
            return response.data[0]
        return None
    
    async def get_or_create_file_record(
        self,
        user_id: str,
        drive_file_id: str,
        name: str,
        mime_type: str,
        size_bytes: Optional[int] = None,
        parent_folder_id: Optional[str] = None,
        is_folder: bool = False,
    ) -> Dict[str, Any]:
        """
        Get existing file record or create new one
        
        Args:
            user_id: UUID of the file owner
            drive_file_id: Google Drive file ID
            name: File name
            mime_type: MIME type
            size_bytes: File size in bytes
            parent_folder_id: Parent folder UUID
            is_folder: Whether this is a folder
            
        Returns:
            File record from database
        """
        # Try to get existing file
        response = self.supabase.client.table("files").select("*").eq(
            "user_id", user_id
        ).eq("drive_file_id", drive_file_id).execute()
        
        if response.data and len(response.data) > 0:
            # Update existing file
            file_id = response.data[0]["id"]
            update_data = {
                "name": name,
                "mime_type": mime_type,
                "updated_at": datetime.utcnow().isoformat()
            }
            if size_bytes is not None:
                update_data["size_bytes"] = size_bytes
            if parent_folder_id is not None:
                update_data["parent_folder_id"] = parent_folder_id
            
            response = self.supabase.client.table("files").update(
                update_data
            ).eq("id", file_id).execute()
            return response.data[0]
        else:
            # Create new file
            file_data = {
                "user_id": user_id,
                "drive_file_id": drive_file_id,
                "name": name,
                "mime_type": mime_type,
                "is_folder": is_folder,
                "is_trashed": False,
            }
            if size_bytes is not None:
                file_data["size_bytes"] = size_bytes
            if parent_folder_id is not None:
                file_data["parent_folder_id"] = parent_folder_id
            
            response = self.supabase.client.table("files").insert(file_data).execute()
            return response.data[0]
    
    async def share_folder_recursively(
        self,
        folder_id: str,
        owner_id: str,
        shared_with_email: str,
        permission: str,
        shared_with_user_id: Optional[str] = None,
    ) -> int:
        """
        Share a folder and all its contents recursively
        
        Args:
            folder_id: UUID of the folder
            owner_id: UUID of the folder owner
            shared_with_email: Email of the person being shared with
            permission: 'viewer' or 'editor'
            shared_with_user_id: UUID of the user being shared with
            
        Returns:
            Number of files shared
        """
        count = 0
        
        # Share the folder itself
        await self.create_share(
            file_id=folder_id,
            owner_id=owner_id,
            shared_with_email=shared_with_email,
            permission=permission,
            shared_with_user_id=shared_with_user_id,
        )
        count += 1
        
        # Get all children of this folder
        children = self.supabase.client.table("files").select("*").eq(
            "parent_folder_id", folder_id
        ).eq("is_trashed", False).execute()
        
        if children.data:
            for child in children.data:
                if child["is_folder"]:
                    # Recursively share subfolders
                    count += await self.share_folder_recursively(
                        folder_id=child["id"],
                        owner_id=owner_id,
                        shared_with_email=shared_with_email,
                        permission=permission,
                        shared_with_user_id=shared_with_user_id,
                    )
                else:
                    # Share files
                    await self.create_share(
                        file_id=child["id"],
                        owner_id=owner_id,
                        shared_with_email=shared_with_email,
                        permission=permission,
                        shared_with_user_id=shared_with_user_id,
                    )
                    count += 1
        
        return count


# Singleton instance
_sharing_service: Optional[SharingService] = None


def get_sharing_service() -> SharingService:
    """Get or create sharing service singleton"""
    global _sharing_service
    if _sharing_service is None:
        _sharing_service = SharingService()
    return _sharing_service
