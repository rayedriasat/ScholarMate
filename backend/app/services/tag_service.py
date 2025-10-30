"""Service for managing tags"""
from typing import List, Dict, Any, Optional
from uuid import UUID
from ..services.supabase_service import get_supabase_service
from ..utils.logging_config import get_logger

logger = get_logger(__name__)


class TagService:
    """Service for tag operations"""
    
    def __init__(self):
        self.supabase = get_supabase_service()
    
    async def get_tags_by_user(self, user_id: UUID) -> List[Dict[str, Any]]:
        """
        Get all tags for a user with document counts
        
        Args:
            user_id: User UUID
            
        Returns:
            List of tag records with document counts
        """
        try:
            # Get tags
            response = self.supabase.client.table("tags").select("*").eq("user_id", str(user_id)).order("name").execute()
            
            tags = response.data
            
            # Get document counts for each tag
            for tag in tags:
                count_response = self.supabase.client.table("file_tags").select("id", count="exact").eq("tag_id", tag["id"]).execute()
                tag["document_count"] = count_response.count if count_response.count else 0
            
            logger.info(f"Retrieved {len(tags)} tags for user {user_id}")
            return tags
            
        except Exception as e:
            logger.error(f"Error getting tags for user {user_id}: {e}")
            raise
    
    async def create_tag(
        self,
        user_id: UUID,
        name: str,
        color: str = "#2196F3"
    ) -> Dict[str, Any]:
        """
        Create a new tag
        
        Args:
            user_id: User UUID
            name: Tag name
            color: Hex color code
            
        Returns:
            Created tag record
        """
        try:
            # Check for duplicate tag name for this user
            existing = self.supabase.client.table("tags").select("*").eq("user_id", str(user_id)).eq("name", name).execute()
            
            if existing.data:
                raise Exception(f"Tag with name '{name}' already exists")
            
            tag_data = {
                "user_id": str(user_id),
                "name": name,
                "color": color
            }
            
            response = self.supabase.client.table("tags").insert(tag_data).execute()
            
            if response.data:
                tag = response.data[0]
                tag["document_count"] = 0
                logger.info(f"Created tag {tag['id']} for user {user_id}")
                return tag
            else:
                raise Exception("Failed to create tag")
                
        except Exception as e:
            logger.error(f"Error creating tag: {e}")
            raise
    
    async def update_tag(
        self,
        tag_id: UUID,
        user_id: UUID,
        updates: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Update an existing tag
        
        Args:
            tag_id: Tag UUID
            user_id: User UUID
            updates: Fields to update
            
        Returns:
            Updated tag record
        """
        try:
            # Verify ownership
            existing = self.supabase.client.table("tags").select("*").eq("id", str(tag_id)).eq("user_id", str(user_id)).execute()
            
            if not existing.data:
                raise Exception("Tag not found or access denied")
            
            # Check for duplicate name if name is being updated
            if "name" in updates:
                duplicate = self.supabase.client.table("tags").select("*").eq("user_id", str(user_id)).eq("name", updates["name"]).neq("id", str(tag_id)).execute()
                
                if duplicate.data:
                    raise Exception(f"Tag with name '{updates['name']}' already exists")
            
            # Update tag
            response = self.supabase.client.table("tags").update(updates).eq("id", str(tag_id)).execute()
            
            if response.data:
                tag = response.data[0]
                # Get document count
                count_response = self.supabase.client.table("file_tags").select("id", count="exact").eq("tag_id", str(tag_id)).execute()
                tag["document_count"] = count_response.count if count_response.count else 0
                
                logger.info(f"Updated tag {tag_id}")
                return tag
            else:
                raise Exception("Failed to update tag")
                
        except Exception as e:
            logger.error(f"Error updating tag {tag_id}: {e}")
            raise
    
    async def delete_tag(
        self,
        tag_id: UUID,
        user_id: UUID
    ) -> bool:
        """
        Delete a tag and all its file associations
        
        Args:
            tag_id: Tag UUID
            user_id: User UUID
            
        Returns:
            True if deleted successfully
        """
        try:
            # Verify ownership
            existing = self.supabase.client.table("tags").select("*").eq("id", str(tag_id)).eq("user_id", str(user_id)).execute()
            
            if not existing.data:
                raise Exception("Tag not found or access denied")
            
            # Delete file associations first (cascade should handle this, but being explicit)
            self.supabase.client.table("file_tags").delete().eq("tag_id", str(tag_id)).execute()
            
            # Delete tag
            self.supabase.client.table("tags").delete().eq("id", str(tag_id)).execute()
            
            logger.info(f"Deleted tag {tag_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error deleting tag {tag_id}: {e}")
            raise
    
    async def add_tag_to_file(
        self,
        user_id: UUID,
        file_id: str,
        tag_id: UUID
    ) -> Dict[str, Any]:
        """
        Add a tag to a file
        
        Args:
            user_id: User UUID
            file_id: Google Drive file ID
            tag_id: Tag UUID
            
        Returns:
            Created file-tag relationship
        """
        try:
            # Verify tag ownership
            tag = self.supabase.client.table("tags").select("*").eq("id", str(tag_id)).eq("user_id", str(user_id)).execute()
            
            if not tag.data:
                raise Exception("Tag not found or access denied")
            
            # Check if association already exists
            existing = self.supabase.client.table("file_tags").select("*").eq("file_id", file_id).eq("tag_id", str(tag_id)).execute()
            
            if existing.data:
                logger.info(f"Tag {tag_id} already associated with file {file_id}")
                return existing.data[0]
            
            # Create association
            file_tag_data = {
                "user_id": str(user_id),
                "file_id": file_id,
                "tag_id": str(tag_id)
            }
            
            response = self.supabase.client.table("file_tags").insert(file_tag_data).execute()
            
            if response.data:
                logger.info(f"Added tag {tag_id} to file {file_id}")
                return response.data[0]
            else:
                raise Exception("Failed to add tag to file")
                
        except Exception as e:
            logger.error(f"Error adding tag to file: {e}")
            raise
    
    async def remove_tag_from_file(
        self,
        user_id: UUID,
        file_id: str,
        tag_id: UUID
    ) -> bool:
        """
        Remove a tag from a file
        
        Args:
            user_id: User UUID
            file_id: Google Drive file ID
            tag_id: Tag UUID
            
        Returns:
            True if removed successfully
        """
        try:
            # Delete association
            self.supabase.client.table("file_tags").delete().eq("file_id", file_id).eq("tag_id", str(tag_id)).eq("user_id", str(user_id)).execute()
            
            logger.info(f"Removed tag {tag_id} from file {file_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error removing tag from file: {e}")
            raise
    
    async def get_tags_for_file(
        self,
        user_id: UUID,
        file_id: str
    ) -> List[Dict[str, Any]]:
        """
        Get all tags for a file
        
        Args:
            user_id: User UUID
            file_id: Google Drive file ID
            
        Returns:
            List of tags
        """
        try:
            # Get file-tag associations
            file_tags = self.supabase.client.table("file_tags").select("tag_id").eq("file_id", file_id).eq("user_id", str(user_id)).execute()
            
            if not file_tags.data:
                return []
            
            tag_ids = [ft["tag_id"] for ft in file_tags.data]
            
            # Get tag details
            tags = self.supabase.client.table("tags").select("*").in_("id", tag_ids).execute()
            
            logger.info(f"Retrieved {len(tags.data)} tags for file {file_id}")
            return tags.data
            
        except Exception as e:
            logger.error(f"Error getting tags for file {file_id}: {e}")
            raise
    
    async def bulk_tag_files(
        self,
        user_id: UUID,
        file_ids: List[str],
        tag_ids: List[UUID]
    ) -> Dict[str, Any]:
        """
        Apply multiple tags to multiple files
        
        Args:
            user_id: User UUID
            file_ids: List of Google Drive file IDs
            tag_ids: List of tag UUIDs
            
        Returns:
            Result with counts
        """
        tagged_count = 0
        failed_count = 0
        
        try:
            # Verify all tags belong to user
            tags = self.supabase.client.table("tags").select("id").eq("user_id", str(user_id)).in_("id", [str(tid) for tid in tag_ids]).execute()
            
            if len(tags.data) != len(tag_ids):
                raise Exception("One or more tags not found or access denied")
            
            # Create associations
            for file_id in file_ids:
                for tag_id in tag_ids:
                    try:
                        await self.add_tag_to_file(user_id, file_id, tag_id)
                        tagged_count += 1
                    except Exception as e:
                        logger.error(f"Error tagging file {file_id} with tag {tag_id}: {e}")
                        failed_count += 1
            
            result = {
                "success": True,
                "tagged_count": tagged_count,
                "failed_count": failed_count,
                "message": f"Tagged {tagged_count} file-tag pairs, {failed_count} failed"
            }
            
            logger.info(f"Bulk tag completed: {result['message']}")
            return result
            
        except Exception as e:
            logger.error(f"Error during bulk tagging: {e}")
            raise


# Singleton instance
_tag_service = None


def get_tag_service() -> TagService:
    """Get or create tag service instance"""
    global _tag_service
    if _tag_service is None:
        _tag_service = TagService()
    return _tag_service
