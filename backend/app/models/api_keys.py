"""
API Key Management Pydantic models.
"""

from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime


class APIKeyCreate(BaseModel):
    """Request to create/update an API key."""
    provider: str = Field(..., description="AI provider name (groq, openai, anthropic, cohere, google, openrouter)")
    api_key: str = Field(..., description="Plain API key (will be encrypted)")
    priority: int = Field(0, ge=0, le=100, description="Priority for provider selection (0-100, higher = preferred)")


class APIKeyUpdate(BaseModel):
    """Request to update an API key."""
    api_key: Optional[str] = Field(None, description="New API key (will be encrypted)")
    is_active: Optional[bool] = Field(None, description="Whether key is active")
    priority: Optional[int] = Field(None, ge=0, le=100, description="Priority for provider selection")


class APIKeyResponse(BaseModel):
    """Response with API key metadata (never includes actual key)."""
    id: str = Field(..., description="Key UUID")
    provider: str = Field(..., description="AI provider name")
    is_active: bool = Field(..., description="Whether key is active")
    is_validated: bool = Field(..., description="Whether key has been validated")
    validation_error: Optional[str] = Field(None, description="Last validation error if any")
    last_validated_at: Optional[datetime] = Field(None, description="Last validation timestamp")
    priority: int = Field(..., description="Priority for provider selection")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    masked_key: str = Field(..., description="Masked key for display (e.g., 'sk-...xyz')")


class APIKeyValidateRequest(BaseModel):
    """Request to validate an API key."""
    provider: str = Field(..., description="AI provider name")
    api_key: str = Field(..., description="API key to validate")


class APIKeyValidateResponse(BaseModel):
    """Response from API key validation."""
    is_valid: bool = Field(..., description="Whether key is valid")
    provider: str = Field(..., description="AI provider name")
    error: Optional[str] = Field(None, description="Error message if invalid")
    model_info: Optional[Dict[str, Any]] = Field(None, description="Available models or provider info")


class APIKeyListResponse(BaseModel):
    """Response with list of user's API keys."""
    keys: List[APIKeyResponse] = Field(..., description="List of API keys")
    total: int = Field(..., description="Total number of keys")


class UsageLogCreate(BaseModel):
    """Internal model for creating usage logs."""
    user_id: str
    provider: str
    endpoint: str
    request_tokens: int = 0
    response_tokens: int = 0
    total_tokens: int = 0
    cost_estimate: float = 0.0
    status: str  # 'success', 'error', 'rate_limit'
    error_message: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class UsageStats(BaseModel):
    """Usage statistics for a provider."""
    provider: str = Field(..., description="AI provider name")
    total_requests: int = Field(..., description="Total number of requests")
    total_tokens: int = Field(..., description="Total tokens used")
    total_cost: float = Field(..., description="Total estimated cost in USD")
    success_rate: float = Field(..., description="Success rate percentage")


class UsageStatsResponse(BaseModel):
    """Response with usage statistics."""
    stats: List[UsageStats] = Field(..., description="Usage statistics by provider")
    period_start: datetime = Field(..., description="Statistics period start")
    period_end: datetime = Field(..., description="Statistics period end")


class ProviderConfig(BaseModel):
    """Configuration for an AI provider."""
    name: str = Field(..., description="Provider name")
    display_name: str = Field(..., description="Display name for UI")
    supports_chat: bool = Field(..., description="Whether provider supports chat")
    supports_embeddings: bool = Field(..., description="Whether provider supports embeddings")
    default_chat_model: Optional[str] = Field(None, description="Default chat model")
    default_embedding_model: Optional[str] = Field(None, description="Default embedding model")
    api_key_format: str = Field(..., description="Expected API key format (for validation)")
    docs_url: str = Field(..., description="Documentation URL")


class ProvidersListResponse(BaseModel):
    """Response with list of supported providers."""
    providers: List[ProviderConfig] = Field(..., description="List of supported providers")
