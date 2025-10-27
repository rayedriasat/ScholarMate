"""Annotation endpoints"""
from fastapi import APIRouter, HTTPException, status, Query
from uuid import UUID
from typing import List
from ..models.annotation import (
    AnnotationCreate,
    AnnotationUpdate,
    AnnotationResponse,
    AnnotationSyncRequest,
    AnnotationSyncResponse,
    AnnotationListResponse
)
from ..services.annotation_service import get_annotation_service
from ..utils.logging_config import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/api/annotations", tags=["annotations"])


@router.get("/{file_id}", response_model=AnnotationListResponse)
async def get_annotations(
    file_id: UUID,
    user_id: UUID = Query(..., description="User UUID")
):
    """
    Get all annotations for a file
    
    Args:
        file_id: File UUID
        user_id: User UUID (query parameter)
        
    Returns:
        List of annotations
    """
    try:
        annotation_service = get_annotation_service()
        annotations = await annotation_service.get_annotations_by_file(file_id, user_id)
        
        return AnnotationListResponse(
            annotations=annotations,
            total=len(annotations)
        )
        
    except Exception as e:
        logger.error(f"Error getting annotations for file {file_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get annotations: {str(e)}"
        )


@router.post("/", response_model=AnnotationResponse, status_code=status.HTTP_201_CREATED)
async def create_annotation(
    annotation: AnnotationCreate,
    user_id: UUID = Query(..., description="User UUID")
):
    """
    Create a new annotation
    
    Args:
        annotation: Annotation data
        user_id: User UUID (query parameter)
        
    Returns:
        Created annotation
    """
    try:
        annotation_service = get_annotation_service()
        
        created = await annotation_service.create_annotation(
            user_id=user_id,
            file_id=annotation.file_id,
            annotation_type=annotation.annotation_type,
            page_number=annotation.page_number,
            position_data=annotation.position_data.model_dump(),
            content=annotation.content,
            color=annotation.color
        )
        
        return AnnotationResponse(**created)
        
    except Exception as e:
        logger.error(f"Error creating annotation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create annotation: {str(e)}"
        )


@router.post("/sync", response_model=AnnotationSyncResponse)
async def sync_annotations(
    request: AnnotationSyncRequest,
    user_id: UUID = Query(..., description="User UUID"),
    file_id: UUID = Query(..., description="File UUID")
):
    """
    Bulk sync annotations with conflict resolution
    
    Uses last-write-wins strategy based on updated_at timestamp.
    Preserves annotation version history in database.
    
    Args:
        request: Sync request with annotations
        user_id: User UUID (query parameter)
        file_id: File UUID (query parameter)
        
    Returns:
        Sync result with counts and conflicts
    """
    try:
        annotation_service = get_annotation_service()
        
        # Convert annotations to dict format
        annotations_data = [
            {
                "file_id": str(ann.file_id),
                "annotation_type": ann.annotation_type,
                "page_number": ann.page_number,
                "position_data": ann.position_data.model_dump(),
                "content": ann.content,
                "color": ann.color
            }
            for ann in request.annotations
        ]
        
        result = await annotation_service.sync_annotations(
            user_id=user_id,
            file_id=file_id,
            annotations=annotations_data
        )
        
        return AnnotationSyncResponse(**result)
        
    except Exception as e:
        logger.error(f"Error syncing annotations: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to sync annotations: {str(e)}"
        )


@router.put("/{annotation_id}", response_model=AnnotationResponse)
async def update_annotation(
    annotation_id: UUID,
    annotation: AnnotationUpdate,
    user_id: UUID = Query(..., description="User UUID")
):
    """
    Update an existing annotation
    
    Args:
        annotation_id: Annotation UUID
        annotation: Update data
        user_id: User UUID (query parameter)
        
    Returns:
        Updated annotation
    """
    try:
        annotation_service = get_annotation_service()
        
        # Build update dict with only provided fields
        updates = {}
        if annotation.annotation_type is not None:
            updates["annotation_type"] = annotation.annotation_type
        if annotation.page_number is not None:
            updates["page_number"] = annotation.page_number
        if annotation.position_data is not None:
            updates["position_data"] = annotation.position_data.model_dump()
        if annotation.content is not None:
            updates["content"] = annotation.content
        if annotation.color is not None:
            updates["color"] = annotation.color
        
        updated = await annotation_service.update_annotation(
            annotation_id=annotation_id,
            user_id=user_id,
            updates=updates
        )
        
        return AnnotationResponse(**updated)
        
    except Exception as e:
        logger.error(f"Error updating annotation {annotation_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update annotation: {str(e)}"
        )


@router.delete("/{annotation_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_annotation(
    annotation_id: UUID,
    user_id: UUID = Query(..., description="User UUID")
):
    """
    Delete an annotation
    
    Args:
        annotation_id: Annotation UUID
        user_id: User UUID (query parameter)
    """
    try:
        annotation_service = get_annotation_service()
        await annotation_service.delete_annotation(annotation_id, user_id)
        
    except Exception as e:
        logger.error(f"Error deleting annotation {annotation_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete annotation: {str(e)}"
        )
