"""
Embeddings API endpoints.
Provides embedding generation for on-device clients (future Android support).
"""

import logging
from typing import List
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel

from ..services.embedding_service import get_embedding_service, EmbeddingStrategy

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/embeddings", tags=["embeddings"])


class EmbeddingRequest(BaseModel):
    """Request model for embedding generation."""
    texts: List[str]
    strategy: str = "auto"  # "auto", "api", or "local"


class EmbeddingResponse(BaseModel):
    """Response model for embedding generation."""
    embeddings: List[List[float]]
    strategy_used: str
    count: int


class HealthResponse(BaseModel):
    """Response model for embedding service health check."""
    api_available: bool
    local_available: bool
    recommended_strategy: str


@router.post("/generate", response_model=EmbeddingResponse)
async def generate_embeddings(request: EmbeddingRequest):
    """
    Generate embeddings for text inputs.
    
    This endpoint allows clients (including future on-device implementations)
    to request embeddings from the backend when needed.
    
    Args:
        request: Embedding request with texts and strategy
        
    Returns:
        Embeddings with metadata
    """
    try:
        # Validate strategy
        strategy_map = {
            "auto": EmbeddingStrategy.AUTO,
            "api": EmbeddingStrategy.API,
            "local": EmbeddingStrategy.LOCAL
        }
        
        strategy = strategy_map.get(request.strategy.lower(), EmbeddingStrategy.AUTO)
        
        # Get embedding service
        embedding_service = get_embedding_service(strategy=strategy)
        
        # Generate embeddings
        embeddings = await embedding_service.generate_embeddings(
            texts=request.texts,
            strategy=strategy
        )
        
        # Determine which strategy was actually used
        # (AUTO may have fallen back from API to local)
        strategy_used = "api" if await embedding_service.is_api_available() else "local"
        
        return EmbeddingResponse(
            embeddings=embeddings,
            strategy_used=strategy_used,
            count=len(embeddings)
        )
        
    except Exception as e:
        logger.error(f"Embedding generation failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health", response_model=HealthResponse)
async def check_embedding_health():
    """
    Check embedding service health and availability.
    
    Returns information about which embedding strategies are available
    and which one is recommended.
    
    Returns:
        Health status with recommendations
    """
    try:
        embedding_service = get_embedding_service()
        
        # Check API availability
        api_available = await embedding_service.is_api_available()
        
        # Local is always available (can be loaded on demand)
        local_available = True
        
        # Recommend API if available (faster, no RAM usage)
        recommended = "api" if api_available else "local"
        
        return HealthResponse(
            api_available=api_available,
            local_available=local_available,
            recommended_strategy=recommended
        )
        
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
