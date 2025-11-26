"""
Ingestion-related Pydantic models for RAG indexing request/response validation.
"""

from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field


class StartIndexingRequest(BaseModel):
    """Request to start indexing a file."""
    user_id: str = Field(..., description="User UUID")
    file_id: str = Field(..., description="Google Drive file ID")
    file_name: Optional[str] = Field(None, description="Optional file name for metadata")
    access_token: str = Field(..., description="User's Google Drive access token")


class StartIndexingResponse(BaseModel):
    """Response from starting indexing."""
    job_id: str = Field(..., description="Job ID for tracking indexing progress")
    status: str = Field(..., description="Initial job status (pending/processing)")
    message: str = Field(..., description="Status message")


class JobStatus(BaseModel):
    """Indexing job status information."""
    job_id: str = Field(..., description="Job ID")
    user_id: str = Field(..., description="User UUID")
    file_id: str = Field(..., description="File ID being indexed")
    status: str = Field(..., description="Job status: pending, processing, completed, failed")
    chunks_processed: int = Field(0, description="Number of chunks processed")
    total_chunks: Optional[int] = Field(None, description="Total number of chunks")
    progress_percentage: float = Field(0.0, description="Progress percentage (0-100)")
    error_message: Optional[str] = Field(None, description="Error message if failed")
    started_at: Optional[datetime] = Field(None, description="Job start timestamp")
    completed_at: Optional[datetime] = Field(None, description="Job completion timestamp")
    created_at: datetime = Field(..., description="Job creation timestamp")


class JobListResponse(BaseModel):
    """Response containing list of indexing jobs."""
    jobs: list[JobStatus] = Field(..., description="List of indexing jobs")
    total: int = Field(..., description="Total number of jobs")


class ReindexRequest(BaseModel):
    """Request to reindex a file."""
    user_id: str = Field(..., description="User UUID")
    file_name: Optional[str] = Field(None, description="Optional file name for metadata")
    access_token: str = Field(..., description="User's Google Drive access token")


class ReindexResponse(BaseModel):
    """Response from reindexing."""
    job_id: str = Field(..., description="Job ID for tracking reindexing progress")
    status: str = Field(..., description="Initial job status")
    message: str = Field(..., description="Status message")
