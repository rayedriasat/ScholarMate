"""Authentication models"""
from pydantic import BaseModel, EmailStr
from typing import Optional


class StoreTokensRequest(BaseModel):
    """Request model for storing OAuth tokens"""
    user_id: str  # Google sub claim
    email: EmailStr
    name: Optional[str] = None
    picture_url: Optional[str] = None
    access_token: str
    refresh_token: Optional[str] = None
    id_token: Optional[str] = None


class StoreTokensResponse(BaseModel):
    """Response model for storing tokens"""
    success: bool
    message: str
    user_id: str  # Database user UUID


class RefreshTokenResponse(BaseModel):
    """Response model for token refresh"""
    access_token: Optional[str] = None
    message: str


class SessionResponse(BaseModel):
    """Response model for session retrieval"""
    access_token: str
    token_expiry: str  # ISO 8601 string
    user_id: str
    email: str
    name: Optional[str] = None
    picture_url: Optional[str] = None

