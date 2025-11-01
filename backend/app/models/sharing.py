"""Pydantic models for sharing endpoints"""
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime


class ShareFileRequest(BaseModel):
    """Request to share a file"""
    user_id: str  # Google sub claim of the owner
    drive_file_id: str  # Google Drive file ID
    file_name: str
    mime_type: str
    shared_with_email: EmailStr
    permission: str  # 'viewer' or 'editor'
    is_folder: bool = False
    size_bytes: Optional[int] = None


class ShareFileResponse(BaseModel):
    """Response after sharing a file"""
    success: bool
    message: str
    share_id: Optional[str] = None
    files_shared: int = 1  # For folders, this is the count of files shared


class RemoveShareRequest(BaseModel):
    """Request to remove a share"""
    user_id: str  # Google sub claim of the owner
    drive_file_id: str  # Google Drive file ID
    shared_with_email: EmailStr


class RemoveShareResponse(BaseModel):
    """Response after removing a share"""
    success: bool
    message: str


class CollaboratorInfo(BaseModel):
    """Information about a collaborator"""
    email: str
    permission: str  # 'viewer' or 'editor'
    name: Optional[str] = None
    picture_url: Optional[str] = None
    shared_at: datetime


class ListSharesResponse(BaseModel):
    """Response with list of collaborators"""
    success: bool
    collaborators: List[CollaboratorInfo]
