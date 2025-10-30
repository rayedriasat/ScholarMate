"""
AI router for GROQ chat and embedding endpoints.
"""

import logging
from fastapi import APIRouter, HTTPException, status
from typing import Dict, Any

from app.models.ai import (
    ChatRequest,
    ChatResponse,
    EmbeddingRequest,
    EmbeddingResponse,
    TestGROQResponse
)
from app.services.groq_service import get_groq_service
from groq import APIError, RateLimitError, APIConnectionError

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/ai", tags=["AI"])


@router.post("/test-groq", response_model=TestGROQResponse)
async def test_groq_connection() -> TestGROQResponse:
    """
    Test GROQ API connectivity.
    
    Returns:
        TestGROQResponse with connection status
    """
    try:
        logger.info("Testing GROQ API connection")
        groq_service = get_groq_service()
        result = groq_service.test_connection()
        
        return TestGROQResponse(**result)
        
    except Exception as e:
        logger.error(f"GROQ connection test failed: {str(e)}")
        return TestGROQResponse(
            status="error",
            message="Failed to test GROQ connection",
            error=str(e)
        )


@router.post("/chat", response_model=ChatResponse)
async def chat_completion(request: ChatRequest) -> ChatResponse:
    """
    Generate chat completion using GROQ.
    
    Args:
        request: ChatRequest with messages and parameters
        
    Returns:
        ChatResponse with generated content
        
    Raises:
        HTTPException: For API errors or rate limits
    """
    try:
        logger.info(f"Chat completion request with {len(request.messages)} messages")
        
        groq_service = get_groq_service()
        
        # Convert Pydantic models to dicts
        messages = [msg.model_dump() for msg in request.messages]
        
        # Call GROQ service
        result = await groq_service.chat(
            messages=messages,
            temperature=request.temperature,
            max_tokens=request.max_tokens,
            stream=request.stream
        )
        
        return ChatResponse(**result)
        
    except RateLimitError as e:
        logger.error(f"GROQ rate limit exceeded: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="GROQ API rate limit exceeded. Please try again later."
        )
    except APIConnectionError as e:
        logger.error(f"GROQ API connection error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Unable to connect to GROQ API. Please try again later."
        )
    except APIError as e:
        logger.error(f"GROQ API error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"GROQ API error: {str(e)}"
        )
    except ValueError as e:
        logger.error(f"Invalid request: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error in chat completion: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred"
        )


@router.post("/embed", response_model=EmbeddingResponse)
async def generate_embeddings(request: EmbeddingRequest) -> EmbeddingResponse:
    """
    Generate embeddings for texts using GROQ.
    
    Note: GROQ doesn't have native embedding support yet.
    This endpoint returns placeholder embeddings.
    
    Args:
        request: EmbeddingRequest with texts to embed
        
    Returns:
        EmbeddingResponse with embedding vectors
        
    Raises:
        HTTPException: For API errors
    """
    try:
        logger.info(f"Embedding request for {len(request.texts)} texts")
        
        if not request.texts:
            raise ValueError("At least one text is required")
        
        groq_service = get_groq_service()
        
        # Generate embeddings
        embeddings = await groq_service.embed(request.texts)
        
        return EmbeddingResponse(
            embeddings=embeddings,
            model=groq_service.embedding_model,
            count=len(embeddings)
        )
        
    except ValueError as e:
        logger.error(f"Invalid request: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error generating embeddings: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate embeddings"
        )
