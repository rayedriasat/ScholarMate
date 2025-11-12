"""Models for PDF metadata and citation generation."""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class PDFMetadata(BaseModel):
    """Metadata extracted from a PDF file."""
    
    title: Optional[str] = None
    authors: List[str] = Field(default_factory=list)
    publication_year: Optional[int] = None
    journal: Optional[str] = None
    conference: Optional[str] = None
    doi: Optional[str] = None
    isbn: Optional[str] = None
    pmid: Optional[str] = None
    arxiv_id: Optional[str] = None
    abstract: Optional[str] = None
    keywords: List[str] = Field(default_factory=list)
    pages: Optional[str] = None
    volume: Optional[str] = None
    issue: Optional[str] = None
    publisher: Optional[str] = None
    url: Optional[str] = None
    
    # File-specific metadata
    file_id: Optional[str] = None
    file_name: Optional[str] = None
    file_size: Optional[int] = None
    created_time: Optional[datetime] = None
    modified_time: Optional[datetime] = None


class CitationRequest(BaseModel):
    """Request to generate citations from an identifier."""
    
    identifier_type: str = Field(..., description="Type: url, doi, isbn, pmid, arxiv")
    identifier_value: str = Field(..., description="The identifier value")


class Citation(BaseModel):
    """Generated citation in various formats."""
    
    apa: str
    mla: str
    chicago: str
    bibtex: str
    harvard: Optional[str] = None
    vancouver: Optional[str] = None
    
    # Source metadata
    metadata: Optional[PDFMetadata] = None


class MetadataExtractionRequest(BaseModel):
    """Request to extract metadata from a PDF."""
    
    file_id: str = Field(..., description="Google Drive file ID")
    file_name: str
    extract_from_content: bool = Field(default=True, description="Extract from PDF content using OCR/parsing")
