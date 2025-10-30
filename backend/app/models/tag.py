"""Tag models for request/response validation"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from uuid import UUID


class TagBase(BaseModel):
    """Base tag model"""
    name: str = Field(..., min_length=1, max_length=50, description="Tag name")
    color: str = Field(default="#2196F3", pattern="^#[0-9A-Fa-f]{6}$", description="Hex color code")


class TagCreate(TagBase):
    """Model for creating a new tag"""
    pass


class TagUpdate(BaseModel):
    """Model for updating a tag"""
    name: Optional[str] = Field(None, min_length=1, max_length=50)
    color: Optional[str] = Field(None, pattern="^#[0-9A-Fa-f]{6}$")


class TagResponse(TagBase):
    """Model for tag response"""
    id: UUID
    user_id: UUID
    created_at: datetime
    updated_at: datetime
    document_count: Optional[int] = 0

    class Config:
        from_attributes = True


class FileTagCreate(BaseModel):
    """Model for adding a tag to a file"""
    file_id: str = Field(..., description="Google Drive file ID")
    tag_id: UUID


class FileTagResponse(BaseModel):
    """Model for file-tag relationship response"""
    id: UUID
    file_id: str
    tag_id: UUID
    user_id: UUID
    created_at: datetime

    class Config:
        from_attributes = True


class FileTagsResponse(BaseModel):
    """Response for file tags"""
    file_id: str
    tags: List[TagResponse]


class TagListResponse(BaseModel):
    """Response for listing tags"""
    tags: List[TagResponse]
    total: int


class BulkTagRequest(BaseModel):
    """Model for bulk tagging operations"""
    file_ids: List[str] = Field(..., min_items=1, description="List of Google Drive file IDs")
    tag_ids: List[UUID] = Field(..., min_items=1, description="List of tag UUIDs to apply")


class BulkTagResponse(BaseModel):
    """Response for bulk tagging"""
    success: bool
    tagged_count: int
    failed_count: int
    message: str
