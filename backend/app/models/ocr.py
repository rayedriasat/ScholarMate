"""OCR request and response models."""
from pydantic import BaseModel, Field
from typing import List, Optional


class OCRProcessRequest(BaseModel):
    """Request model for OCR processing."""
    images: List[str] = Field(..., description="Base64 encoded images")
    language: str = Field(default="eng", description="OCR language code (e.g., 'eng', 'fra', 'deu')")


class OCRPageResult(BaseModel):
    """OCR result for a single page."""
    page_number: int
    text: str
    confidence: Optional[float] = None


class OCRProcessResponse(BaseModel):
    """Response model for OCR processing."""
    success: bool
    pages: List[OCRPageResult]
    total_pages: int
    message: Optional[str] = None
