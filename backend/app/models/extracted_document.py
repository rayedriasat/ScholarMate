"""Extracted document models for request/response validation"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


class ExtractedDocumentBase(BaseModel):
    """Base extracted document model"""
    document_type: str = Field(..., description="Type of document (Hospital, Appointment, ID Card, Bill, Prescription, etc.)")
    extracted_data: Dict[str, Any] = Field(..., description="Key-value pairs of extracted fields")
    summary: str = Field(..., min_length=1, max_length=500, description="1-2 line AI-generated summary")
    image_url: Optional[str] = Field(None, description="Google Drive file ID or URL to original image")
    tags: List[str] = Field(default_factory=list, description="Auto-generated tags")


class ExtractedDocumentCreate(ExtractedDocumentBase):
    """Model for creating a new extracted document"""
    pass


class ExtractedDocumentUpdate(BaseModel):
    """Model for updating an extracted document"""
    document_type: Optional[str] = None
    extracted_data: Optional[Dict[str, Any]] = None
    summary: Optional[str] = Field(None, min_length=1, max_length=500)
    image_url: Optional[str] = None
    tags: Optional[List[str]] = None


class ExtractedDocumentResponse(ExtractedDocumentBase):
    """Model for extracted document response"""
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DocumentExtractionRequest(BaseModel):
    """Request model for document extraction from OCR text"""
    ocr_text: str = Field(..., min_length=1, description="OCR extracted text from document image")


class DocumentExtractionResponse(BaseModel):
    """Response model for document extraction"""
    document_type: str
    extracted_fields: Dict[str, Any]
    summary: str
    tags: List[str]


class ExtractedDocumentListResponse(BaseModel):
    """Response for listing extracted documents"""
    documents: List[ExtractedDocumentResponse]
    total: int


class ExtractedDocumentSearchRequest(BaseModel):
    """Request model for searching extracted documents"""
    q: Optional[str] = Field(None, description="Search query")
    type: Optional[str] = Field(None, description="Filter by document type")
    tags: Optional[List[str]] = Field(None, description="Filter by tags")
