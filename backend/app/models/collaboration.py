"""Collaboration models for real-time PDF sessions"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from uuid import UUID
from datetime import datetime
from enum import Enum


class CursorPosition(BaseModel):
    """User cursor position in PDF"""
    x: float = Field(..., description="X coordinate (0-1 normalized)")
    y: float = Field(..., description="Y coordinate (0-1 normalized)")
    page_number: int = Field(..., description="PDF page number")


class CollaborationAnnotation(BaseModel):
    """Real-time annotation data"""
    id: Optional[str] = None
    user_id: str
    user_name: str
    user_color: str  # Hex color for user identification
    annotation_type: str  # highlight, drawing, comment
    page_number: int
    position_data: Dict[str, Any]
    content: Optional[str] = None
    color: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class SessionRole(str, Enum):
    """User role in collaboration session"""
    OWNER = "owner"
    EDITOR = "editor"
    VIEWER = "viewer"


class SessionParticipant(BaseModel):
    """Participant in collaboration session"""
    user_id: str
    user_name: str
    user_email: str
    user_color: str  # Assigned color for cursor/annotations
    role: SessionRole
    cursor_position: Optional[CursorPosition] = None
    last_seen: datetime = Field(default_factory=datetime.utcnow)


class CollaborationSessionCreate(BaseModel):
    """Create collaboration session request"""
    file_id: UUID
    file_name: str
    owner_id: str
    owner_name: str
    owner_email: str
    default_role: SessionRole = SessionRole.EDITOR


class CollaborationSessionResponse(BaseModel):
    """Collaboration session response"""
    session_id: str
    file_id: str
    file_name: str
    owner_id: str
    share_link: str
    participants: List[SessionParticipant]
    created_at: datetime
    expires_at: Optional[datetime] = None


class JoinSessionRequest(BaseModel):
    """Join collaboration session request"""
    session_id: str
    user_id: str
    user_name: str
    user_email: str


class CursorUpdateMessage(BaseModel):
    """Real-time cursor position update"""
    session_id: str
    user_id: str
    cursor_position: Optional[CursorPosition]


class AnnotationUpdateMessage(BaseModel):
    """Real-time annotation update"""
    session_id: str
    annotation: CollaborationAnnotation
    action: str  # create, update, delete


class ParticipantUpdateMessage(BaseModel):
    """Participant joined/left notification"""
    session_id: str
    participant: SessionParticipant
    action: str  # joined, left
