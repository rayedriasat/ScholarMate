"""
API Key Management Router.
Endpoints for managing user AI provider API keys.
"""

import logging
from fastapi import APIRouter, HTTPException, status, Query
from typing import Optional

from app.models.api_keys import (
    APIKeyCreate,
    APIKeyUpdate,
    APIKeyResponse,
    APIKeyValidateRequest,
    APIKeyValidateResponse,
    APIKeyListResponse,
    UsageStatsResponse,
    UsageStats,
    ProvidersListResponse,
    ProviderConfig
)
from app.services.api_key_service import get_api_key_service
from app.services.provider_service import ProviderFactory
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/keys", tags=["API Keys"])


@router.get("/providers", response_model=ProvidersListResponse)
async def list_supported_providers() -> ProvidersListResponse:
    """
    Get list of supported AI providers.
    
    Returns:
        ProvidersListResponse with provider configurations
    """
    try:
        providers_data = ProviderFactory.get_supported_providers()
        providers = [ProviderConfig(**p) for p in providers_data]
        
        return ProvidersListResponse(providers=providers)
        
    except Exception as e:
        logger.error(f"Error listing providers: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to list providers"
        )


@router.post("/validate", response_model=APIKeyValidateResponse)
async def validate_api_key(request: APIKeyValidateRequest) -> APIKeyValidateResponse:
    """
    Validate an API key without saving it.
    
    Args:
        request: APIKeyValidateRequest with provider and key
        
    Returns:
        APIKeyValidateResponse with validation result
    """
    try:
        logger.info(f"Validating API key for provider: {request.provider}")
        
        api_key_service = get_api_key_service()
        result = await api_key_service.validate_key(request.provider, request.api_key)
        
        return APIKeyValidateResponse(**result)
        
    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error validating key: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to validate API key"
        )


@router.post("/{user_id}", response_model=APIKeyResponse)
async def create_or_update_key(
    user_id: str,
    request: APIKeyCreate,
    validate: bool = Query(True, description="Validate key before saving")
) -> APIKeyResponse:
    """
    Create or update user's API key for a provider.
    
    Args:
        user_id: User UUID
        request: APIKeyCreate with provider and key
        validate: Whether to validate key before saving
        
    Returns:
        APIKeyResponse with key metadata
    """
    try:
        logger.info(f"Creating/updating API key for user {user_id}, provider {request.provider}")
        
        api_key_service = get_api_key_service()
        result = await api_key_service.create_or_update_key(
            user_id=user_id,
            provider=request.provider,
            api_key=request.api_key,
            priority=request.priority,
            validate=validate
        )
        
        # Remove encrypted_key from response
        result.pop("encrypted_key", None)
        
        return APIKeyResponse(**result)
        
    except ValueError as e:
        logger.error(f"Error creating/updating key: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to save API key"
        )


@router.get("/{user_id}", response_model=APIKeyListResponse)
async def list_user_keys(user_id: str) -> APIKeyListResponse:
    """
    Get all API keys for a user.
    
    Args:
        user_id: User UUID
        
    Returns:
        APIKeyListResponse with list of keys
    """
    try:
        logger.info(f"Fetching API keys for user {user_id}")
        
        api_key_service = get_api_key_service()
        keys = await api_key_service.get_user_keys(user_id)
        
        # Remove encrypted_key from responses
        for key in keys:
            key.pop("encrypted_key", None)
        
        return APIKeyListResponse(
            keys=[APIKeyResponse(**k) for k in keys],
            total=len(keys)
        )
        
    except ValueError as e:
        logger.error(f"Error fetching keys: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch API keys"
        )


@router.get("/{user_id}/{key_id}", response_model=APIKeyResponse)
async def get_key(user_id: str, key_id: str) -> APIKeyResponse:
    """
    Get specific API key metadata.
    
    Args:
        user_id: User UUID
        key_id: Key UUID
        
    Returns:
        APIKeyResponse with key metadata
    """
    try:
        logger.info(f"Fetching key {key_id} for user {user_id}")
        
        api_key_service = get_api_key_service()
        key = await api_key_service.get_key(user_id, key_id)
        
        if not key:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="API key not found"
            )
        
        # Remove encrypted_key from response
        key.pop("encrypted_key", None)
        
        return APIKeyResponse(**key)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch API key"
        )


@router.patch("/{user_id}/{key_id}", response_model=APIKeyResponse)
async def update_key(
    user_id: str,
    key_id: str,
    request: APIKeyUpdate
) -> APIKeyResponse:
    """
    Update API key status or priority.
    
    Args:
        user_id: User UUID
        key_id: Key UUID
        request: APIKeyUpdate with fields to update
        
    Returns:
        APIKeyResponse with updated key metadata
    """
    try:
        logger.info(f"Updating key {key_id} for user {user_id}")
        
        api_key_service = get_api_key_service()
        
        # If updating the key itself, validate it
        if request.api_key:
            # Get current key to know provider
            current_key = await api_key_service.get_key(user_id, key_id)
            if not current_key:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="API key not found"
                )
            
            # Update with new key
            result = await api_key_service.create_or_update_key(
                user_id=user_id,
                provider=current_key["provider"],
                api_key=request.api_key,
                priority=request.priority if request.priority is not None else current_key["priority"],
                validate=True
            )
        else:
            # Just update status/priority
            result = await api_key_service.update_key_status(
                user_id=user_id,
                key_id=key_id,
                is_active=request.is_active,
                priority=request.priority
            )
        
        # Remove encrypted_key from response
        result.pop("encrypted_key", None)
        
        return APIKeyResponse(**result)
        
    except HTTPException:
        raise
    except ValueError as e:
        logger.error(f"Error updating key: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update API key"
        )


@router.delete("/{user_id}/{key_id}")
async def delete_key(user_id: str, key_id: str):
    """
    Delete user's API key.
    
    Args:
        user_id: User UUID
        key_id: Key UUID
        
    Returns:
        Success message
    """
    try:
        logger.info(f"Deleting key {key_id} for user {user_id}")
        
        api_key_service = get_api_key_service()
        await api_key_service.delete_key(user_id, key_id)
        
        return {"message": "API key deleted successfully"}
        
    except ValueError as e:
        logger.error(f"Error deleting key: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete API key"
        )


@router.get("/{user_id}/usage/stats", response_model=UsageStatsResponse)
async def get_usage_stats(
    user_id: str,
    days: int = Query(30, ge=1, le=365, description="Number of days to look back")
) -> UsageStatsResponse:
    """
    Get usage statistics for user.
    
    Args:
        user_id: User UUID
        days: Number of days to look back (1-365)
        
    Returns:
        UsageStatsResponse with statistics by provider
    """
    try:
        logger.info(f"Fetching usage stats for user {user_id}, last {days} days")
        
        api_key_service = get_api_key_service()
        stats_data = await api_key_service.get_usage_stats(user_id, days)
        
        stats = [UsageStats(**s) for s in stats_data]
        
        period_end = datetime.utcnow()
        period_start = period_end - timedelta(days=days)
        
        return UsageStatsResponse(
            stats=stats,
            period_start=period_start,
            period_end=period_end
        )
        
    except Exception as e:
        logger.error(f"Error fetching usage stats: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to fetch usage statistics"
        )
