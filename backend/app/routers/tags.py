"""Tag endpoints"""
from fastapi import APIRouter, HTTPException, status, Query
from uuid import UUID
from typing import List
from ..models.tag import (
    TagCreate,
    TagUpdate,
    TagResponse,
    TagListResponse,
    FileTagCreate,
    FileTagResponse,
    FileTagsResponse,
    BulkTagRequest,
    BulkTagResponse
)
from ..services.tag_service import get_tag_service
from ..utils.logging_config import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/api/tags", tags=["tags"])


@router.get("/", response_model=TagListResponse)
async def get_tags(
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Get all tags for a user with document counts
    
    Args:
        user_id: User UUID (query parameter)
        
    Returns:
        List of tags with document counts
    """
    try:
        tag_service = get_tag_service()
        tags = await tag_service.get_tags_by_user(user_id)
        
        return TagListResponse(
            tags=[TagResponse(**tag) for tag in tags],
            total=len(tags)
        )
        
    except Exception as e:
        logger.error(f"Error getting tags for user {user_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get tags: {str(e)}"
        )


@router.post("/", response_model=TagResponse, status_code=status.HTTP_201_CREATED)
async def create_tag(
    tag: TagCreate,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Create a new tag
    
    Args:
        tag: Tag data
        user_id: User UUID (query parameter)
        
    Returns:
        Created tag
    """
    try:
        tag_service = get_tag_service()
        
        created = await tag_service.create_tag(
            user_id=user_id,
            name=tag.name,
            color=tag.color
        )
        
        return TagResponse(**created)
        
    except Exception as e:
        logger.error(f"Error creating tag: {e}")
        if "already exists" in str(e):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=str(e)
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create tag: {str(e)}"
        )


@router.put("/{tag_id}", response_model=TagResponse)
async def update_tag(
    tag_id: UUID,
    tag: TagUpdate,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Update an existing tag
    
    Args:
        tag_id: Tag UUID
        tag: Update data
        user_id: User UUID (query parameter)
        
    Returns:
        Updated tag
    """
    try:
        tag_service = get_tag_service()
        
        # Build update dict with only provided fields
        updates = {}
        if tag.name is not None:
            updates["name"] = tag.name
        if tag.color is not None:
            updates["color"] = tag.color
        
        updated = await tag_service.update_tag(
            tag_id=tag_id,
            user_id=user_id,
            updates=updates
        )
        
        return TagResponse(**updated)
        
    except Exception as e:
        logger.error(f"Error updating tag {tag_id}: {e}")
        if "already exists" in str(e):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=str(e)
            )
        if "not found" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=str(e)
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update tag: {str(e)}"
        )


@router.delete("/{tag_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tag(
    tag_id: UUID,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Delete a tag and all its file associations
    
    Args:
        tag_id: Tag UUID
        user_id: User UUID (query parameter)
    """
    try:
        tag_service = get_tag_service()
        await tag_service.delete_tag(tag_id, user_id)
        
    except Exception as e:
        logger.error(f"Error deleting tag {tag_id}: {e}")
        if "not found" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=str(e)
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete tag: {str(e)}"
        )


@router.get("/file/{file_id}", response_model=FileTagsResponse)
async def get_file_tags(
    file_id: str,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Get all tags for a file
    
    Args:
        file_id: Google Drive file ID
        user_id: User UUID (query parameter)
        
    Returns:
        List of tags for the file
    """
    try:
        tag_service = get_tag_service()
        tags = await tag_service.get_tags_for_file(user_id, file_id)
        
        return FileTagsResponse(
            file_id=file_id,
            tags=[TagResponse(**tag) for tag in tags]
        )
        
    except Exception as e:
        logger.error(f"Error getting tags for file {file_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get file tags: {str(e)}"
        )


@router.post("/file", response_model=FileTagResponse, status_code=status.HTTP_201_CREATED)
async def add_tag_to_file(
    file_tag: FileTagCreate,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Add a tag to a file
    
    Args:
        file_tag: File-tag relationship data
        user_id: User UUID (query parameter)
        
    Returns:
        Created file-tag relationship
    """
    try:
        tag_service = get_tag_service()
        
        created = await tag_service.add_tag_to_file(
            user_id=user_id,
            file_id=file_tag.file_id,
            tag_id=file_tag.tag_id
        )
        
        return FileTagResponse(**created)
        
    except Exception as e:
        logger.error(f"Error adding tag to file: {e}")
        if "not found" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=str(e)
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to add tag to file: {str(e)}"
        )


@router.delete("/file/{file_id}/{tag_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_tag_from_file(
    file_id: str,
    tag_id: UUID,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Remove a tag from a file
    
    Args:
        file_id: Google Drive file ID
        tag_id: Tag UUID
        user_id: User UUID (query parameter)
    """
    try:
        tag_service = get_tag_service()
        await tag_service.remove_tag_from_file(user_id, file_id, tag_id)
        
    except Exception as e:
        logger.error(f"Error removing tag from file: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to remove tag from file: {str(e)}"
        )


@router.post("/bulk", response_model=BulkTagResponse)
async def bulk_tag_files(
    request: BulkTagRequest,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Apply multiple tags to multiple files
    
    Args:
        request: Bulk tag request with file IDs and tag IDs
        user_id: User UUID (query parameter)
        
    Returns:
        Bulk tag result with counts
    """
    try:
        tag_service = get_tag_service()
        
        result = await tag_service.bulk_tag_files(
            user_id=user_id,
            file_ids=request.file_ids,
            tag_ids=request.tag_ids
        )
        
        return BulkTagResponse(**result)
        
    except Exception as e:
        logger.error(f"Error bulk tagging files: {e}")
        if "not found" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=str(e)
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to bulk tag files: {str(e)}"
        )
