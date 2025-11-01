"""
AI-related Pydantic models for request/response validation.
"""

from typing import List, Dict, Optional
from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    """Single chat message."""
    role: str = Field(..., description="Message role: 'system', 'user', or 'assistant'")
    content: str = Field(..., description="Message content")


class ChatRequest(BaseModel):
    """Request for chat completion."""
    messages: List[ChatMessage] = Field(..., description="List of chat messages")
    temperature: float = Field(0.7, ge=0, le=2, description="Sampling temperature")
    max_tokens: Optional[int] = Field(None, description="Maximum tokens to generate")
    stream: bool = Field(False, description="Whether to stream the response")


class ChatResponse(BaseModel):
    """Response from chat completion."""
    content: str = Field(..., description="Generated response content")
    model: str = Field(..., description="Model used for generation")
    usage: Dict[str, int] = Field(..., description="Token usage statistics")
    finish_reason: str = Field(..., description="Reason for completion finish")


class EmbeddingRequest(BaseModel):
    """Request for text embeddings."""
    texts: List[str] = Field(..., description="List of texts to embed")


class EmbeddingResponse(BaseModel):
    """Response from embedding generation."""
    embeddings: List[List[float]] = Field(..., description="List of embedding vectors")
    model: str = Field(..., description="Model used for embeddings")
    count: int = Field(..., description="Number of embeddings generated")


class TestGROQResponse(BaseModel):
    """Response from GROQ connection test."""
    status: str = Field(..., description="Connection status: 'success' or 'error'")
    message: str = Field(..., description="Status message")
    model: Optional[str] = Field(None, description="Model name if successful")
    response: Optional[str] = Field(None, description="Test response if successful")
    error: Optional[str] = Field(None, description="Error message if failed")


class RAGChatRequest(BaseModel):
    """Request for RAG-based chat with source filtering."""
    question: str = Field(..., description="User's question")
    user_id: str = Field(..., description="User UUID")
    selected_file_ids: Optional[List[str]] = Field(None, description="Optional list of file IDs to filter sources")
    top_k: int = Field(5, ge=1, le=20, description="Number of chunks to retrieve (1-20)")


class Citation(BaseModel):
    """Citation reference to source document."""
    file_id: str = Field(..., description="File UUID")
    file_name: str = Field(..., description="File name")
    page_number: int = Field(..., description="Page number in document")
    snippet: str = Field("", description="Text snippet from the source")


class RAGChatResponse(BaseModel):
    """Response from RAG-based chat."""
    message: str = Field(..., description="AI-generated answer")
    citations: List[Citation] = Field(..., description="List of source citations")
    timestamp: str = Field(..., description="Response timestamp (ISO format)")
