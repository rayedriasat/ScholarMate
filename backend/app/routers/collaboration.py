"""Collaboration endpoints for real-time PDF sessions"""
from fastapi import APIRouter, HTTPException, status, Query
from uuid import UUID
from typing import Optional
from ..models.collaboration import (
    CollaborationSessionCreate,
    CollaborationSessionResponse,
    JoinSessionRequest,
    CursorUpdateMessage
)
from ..services.collaboration_service import get_collaboration_service
from ..utils.logging_config import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/api/collaboration", tags=["collaboration"])


@router.post("/sessions", response_model=CollaborationSessionResponse, status_code=status.HTTP_201_CREATED)
async def create_session(request: CollaborationSessionCreate):
    """
    Create new collaboration session
    
    Args:
        request: Session creation data
        
    Returns:
        Session with share link
    """
    try:
        service = get_collaboration_service()
        session = await service.create_session(
            file_id=request.file_id,
            file_name=request.file_name,
            owner_id=request.owner_id,
            owner_name=request.owner_name,
            owner_email=request.owner_email,
            default_role=request.default_role.value
        )
        
        return CollaborationSessionResponse(**session)
        
    except Exception as e:
        logger.error(f"Error creating session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create session: {str(e)}"
        )


@router.post("/sessions/join", response_model=CollaborationSessionResponse)
async def join_session(request: JoinSessionRequest):
    """
    Join existing collaboration session
    
    Args:
        request: Join request data
        
    Returns:
        Session data with participants
    """
    try:
        service = get_collaboration_service()
        session = await service.join_session(
            session_id=request.session_id,
            user_id=request.user_id,
            user_name=request.user_name,
            user_email=request.user_email
        )
        
        return CollaborationSessionResponse(**session)
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error joining session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to join session: {str(e)}"
        )


@router.get("/sessions/{session_id}", response_model=CollaborationSessionResponse)
async def get_session(session_id: str):
    """
    Get collaboration session details
    
    Args:
        session_id: Session ID
        
    Returns:
        Session data
    """
    try:
        service = get_collaboration_service()
        session = await service.get_session(session_id)
        
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found"
            )
        
        return CollaborationSessionResponse(**session)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get session: {str(e)}"
        )


@router.delete("/sessions/{session_id}/leave")
async def leave_session(
    session_id: str,
    user_id: str = Query(..., description="User ID")
):
    """
    Leave collaboration session
    
    Args:
        session_id: Session ID
        user_id: User ID
    """
    try:
        service = get_collaboration_service()
        await service.leave_session(session_id, user_id)
        
        return {"message": "Left session successfully"}
        
    except Exception as e:
        logger.error(f"Error leaving session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to leave session: {str(e)}"
        )


@router.post("/sessions/{session_id}/cursor")
async def update_cursor(
    session_id: str,
    cursor: CursorUpdateMessage
):
    """
    Update user cursor position (called frequently)
    
    Args:
        session_id: Session ID
        cursor: Cursor position data
    """
    try:
        service = get_collaboration_service()
        cursor_data = cursor.cursor_position.model_dump() if cursor.cursor_position else None
        
        await service.update_cursor(
            session_id=session_id,
            user_id=cursor.user_id,
            cursor_data=cursor_data
        )
        
        return {"status": "ok"}
        
    except Exception as e:
        logger.error(f"Error updating cursor: {e}")
        # Don't raise exception for cursor updates (too frequent)
        return {"status": "error", "message": str(e)}
