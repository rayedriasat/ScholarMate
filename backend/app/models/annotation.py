"""Annotation models for request/response validation"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from uuid import UUID


class AnnotationPositionData(BaseModel):
    """Position data for annotation (bounding box)"""
    left: float
    top: float
    right: float
    bottom: float


class AnnotationBase(BaseModel):
    """Base annotation model"""
    file_id: UUID
    annotation_type: str = Field(..., description="Type: highlight, underline, strikethrough, comment")
    page_number: int = Field(..., ge=1)
    position_data: AnnotationPositionData
    content: Optional[str] = None
    color: str = Field(default="#FFFF00", description="Hex color code")


class AnnotationCreate(AnnotationBase):
    """Model for creating a new annotation"""
    pass


class AnnotationUpdate(BaseModel):
    """Model for updating an annotation"""
    annotation_type: Optional[str] = None
    page_number: Optional[int] = Field(None, ge=1)
    position_data: Optional[AnnotationPositionData] = None
    content: Optional[str] = None
    color: Optional[str] = None


class AnnotationResponse(AnnotationBase):
    """Model for annotation response"""
    id: UUID
    user_id: UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class AnnotationSyncRequest(BaseModel):
    """Model for bulk annotation sync"""
    annotations: List[AnnotationCreate]


class AnnotationSyncResponse(BaseModel):
    """Response for bulk annotation sync"""
    success: bool
    synced_count: int
    failed_count: int
    conflicts: List[dict] = []
    message: str


class AnnotationListResponse(BaseModel):
    """Response for listing annotations"""
    annotations: List[AnnotationResponse]
    total: int
