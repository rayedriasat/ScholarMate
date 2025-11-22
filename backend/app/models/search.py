"""
Pydantic models for search API.
"""

from pydantic import BaseModel, Field
from typing import List, Optional


class SearchRequest(BaseModel):
    """Request model for advanced search."""
    
    query: str = Field(..., description="Search query (word, phrase, or sentence)")
    user_id: str = Field(..., description="User UUID or Google sub ID")
    max_results: int = Field(default=20, ge=1, le=100, description="Maximum number of results")
    include_semantic: bool = Field(default=True, description="Include semantic content search")


class SearchResultItem(BaseModel):
    """Individual search result."""
    
    file_id: str = Field(..., description="File ID")
    file_name: str = Field(..., description="File name")
    match_type: str = Field(..., description="Type of match: exact, partial, semantic, fuzzy")
    relevance_score: float = Field(..., ge=0.0, le=1.0, description="Relevance score (0-1)")
    snippet: str = Field(default="", description="Text snippet showing match")
    page_number: Optional[int] = Field(None, description="Page number (for content matches)")
    match_context: Optional[str] = Field(None, description="Where match was found: filename or content")
    file_size: Optional[int] = Field(None, description="File size in bytes")
    modified_time: Optional[str] = Field(None, description="Last modified time")
    mime_type: Optional[str] = Field(None, description="MIME type")


class SearchResponse(BaseModel):
    """Response model for search results."""
    
    results: List[SearchResultItem] = Field(..., description="List of search results")
    total_count: int = Field(..., description="Total number of results")
    query: str = Field(..., description="Original search query")
    search_time_ms: int = Field(..., description="Search execution time in milliseconds")
