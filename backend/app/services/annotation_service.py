"""Service for managing annotations"""
from typing import List, Optional, Dict, Any
from uuid import UUID
from datetime import datetime
from ..services.supabase_service import get_supabase_service
from ..utils.logging_config import get_logger

logger = get_logger(__name__)


class AnnotationService:
    """Service for annotation operations"""
    
    def __init__(self):
        self.supabase = get_supabase_service()
    
    async def get_annotations_by_file(
        self,
        file_id: UUID,
        user_id: UUID
    ) -> List[Dict[str, Any]]:
        """
        Get all annotations for a file
        
        Args:
            file_id: File UUID
            user_id: User UUID
            
        Returns:
            List of annotation records
        """
        try:
            # Verify user has access to the file
            file_response = self.supabase.client.table("files").select("*").eq("id", str(file_id)).eq("user_id", str(user_id)).execute()
            
            if not file_response.data:
                logger.warning(f"File not found or access denied: {file_id} for user {user_id}")
                return []
            
            # Get annotations
            response = self.supabase.client.table("annotations").select("*").eq("file_id", str(file_id)).order("page_number").execute()
            
            logger.info(f"Retrieved {len(response.data)} annotations for file {file_id}")
            return response.data
            
        except Exception as e:
            logger.error(f"Error getting annotations for file {file_id}: {e}")
            raise
    
    async def create_annotation(
        self,
        user_id: UUID,
        file_id: UUID,
        annotation_type: str,
        page_number: int,
        position_data: Dict[str, float],
        content: Optional[str] = None,
        color: str = "#FFFF00"
    ) -> Dict[str, Any]:
        """
        Create a new annotation
        
        Args:
            user_id: User UUID
            file_id: File UUID
            annotation_type: Type of annotation
            page_number: Page number
            position_data: Position data (bounding box)
            content: Optional content/text
            color: Hex color code
            
        Returns:
            Created annotation record
        """
        try:
            annotation_data = {
                "user_id": str(user_id),
                "file_id": str(file_id),
                "annotation_type": annotation_type,
                "page_number": page_number,
                "position_data": position_data,
                "content": content,
                "color": color
            }
            
            response = self.supabase.client.table("annotations").insert(annotation_data).execute()
            
            if response.data:
                logger.info(f"Created annotation {response.data[0]['id']} for file {file_id}")
                return response.data[0]
            else:
                raise Exception("Failed to create annotation")
                
        except Exception as e:
            logger.error(f"Error creating annotation: {e}")
            raise
    
    async def update_annotation(
        self,
        annotation_id: UUID,
        user_id: UUID,
        updates: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Update an existing annotation
        
        Args:
            annotation_id: Annotation UUID
            user_id: User UUID
            updates: Fields to update
            
        Returns:
            Updated annotation record
        """
        try:
            # Verify ownership
            existing = self.supabase.client.table("annotations").select("*").eq("id", str(annotation_id)).eq("user_id", str(user_id)).execute()
            
            if not existing.data:
                raise Exception("Annotation not found or access denied")
            
            # Update annotation
            response = self.supabase.client.table("annotations").update(updates).eq("id", str(annotation_id)).execute()
            
            if response.data:
                logger.info(f"Updated annotation {annotation_id}")
                return response.data[0]
            else:
                raise Exception("Failed to update annotation")
                
        except Exception as e:
            logger.error(f"Error updating annotation {annotation_id}: {e}")
            raise
    
    async def delete_annotation(
        self,
        annotation_id: UUID,
        user_id: UUID
    ) -> bool:
        """
        Delete an annotation
        
        Args:
            annotation_id: Annotation UUID
            user_id: User UUID
            
        Returns:
            True if deleted successfully
        """
        try:
            # Verify ownership
            existing = self.supabase.client.table("annotations").select("*").eq("id", str(annotation_id)).eq("user_id", str(user_id)).execute()
            
            if not existing.data:
                raise Exception("Annotation not found or access denied")
            
            # Delete annotation
            self.supabase.client.table("annotations").delete().eq("id", str(annotation_id)).execute()
            
            logger.info(f"Deleted annotation {annotation_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error deleting annotation {annotation_id}: {e}")
            raise
    
    async def sync_annotations(
        self,
        user_id: UUID,
        file_id: UUID,
        annotations: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Bulk sync annotations with conflict resolution
        
        Uses last-write-wins strategy based on updated_at timestamp
        
        Args:
            user_id: User UUID
            file_id: File UUID
            annotations: List of annotations to sync
            
        Returns:
            Sync result with counts and conflicts
        """
        synced_count = 0
        failed_count = 0
        conflicts = []
        
        try:
            # Get existing annotations for the file
            existing_annotations = await self.get_annotations_by_file(file_id, user_id)
            existing_by_id = {ann["id"]: ann for ann in existing_annotations}
            
            for annotation in annotations:
                try:
                    annotation_id = annotation.get("id")
                    
                    if annotation_id and annotation_id in existing_by_id:
                        # Annotation exists - check for conflicts
                        existing = existing_by_id[annotation_id]
                        client_updated = datetime.fromisoformat(annotation.get("updated_at", annotation.get("created_at")))
                        server_updated = datetime.fromisoformat(existing["updated_at"])
                        
                        if client_updated > server_updated:
                            # Client version is newer - update
                            update_data = {
                                "annotation_type": annotation.get("annotation_type"),
                                "page_number": annotation.get("page_number"),
                                "position_data": annotation.get("position_data"),
                                "content": annotation.get("content"),
                                "color": annotation.get("color")
                            }
                            await self.update_annotation(UUID(annotation_id), user_id, update_data)
                            synced_count += 1
                        elif server_updated > client_updated:
                            # Server version is newer - conflict
                            conflicts.append({
                                "annotation_id": annotation_id,
                                "reason": "server_newer",
                                "server_updated_at": existing["updated_at"],
                                "client_updated_at": annotation.get("updated_at")
                            })
                            synced_count += 1  # Still count as synced (server wins)
                        else:
                            # Same timestamp - no conflict
                            synced_count += 1
                    else:
                        # New annotation - create it
                        await self.create_annotation(
                            user_id=user_id,
                            file_id=file_id,
                            annotation_type=annotation.get("annotation_type"),
                            page_number=annotation.get("page_number"),
                            position_data=annotation.get("position_data"),
                            content=annotation.get("content"),
                            color=annotation.get("color", "#FFFF00")
                        )
                        synced_count += 1
                        
                except Exception as e:
                    logger.error(f"Error syncing annotation: {e}")
                    failed_count += 1
            
            result = {
                "success": True,
                "synced_count": synced_count,
                "failed_count": failed_count,
                "conflicts": conflicts,
                "message": f"Synced {synced_count} annotations, {failed_count} failed, {len(conflicts)} conflicts"
            }
            
            logger.info(f"Sync completed for file {file_id}: {result['message']}")
            return result
            
        except Exception as e:
            logger.error(f"Error during bulk sync: {e}")
            raise


# Singleton instance
_annotation_service = None


def get_annotation_service() -> AnnotationService:
    """Get or create annotation service instance"""
    global _annotation_service
    if _annotation_service is None:
        _annotation_service = AnnotationService()
    return _annotation_service
