"""
API Key Management Service.
Handles CRUD operations for user API keys with encryption and validation.
"""

import logging
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta

from .encryption_service import get_encryption_service
from .supabase_service import get_supabase_service
from .provider_service import ProviderFactory, AIProvider

logger = logging.getLogger(__name__)


class APIKeyService:
    """Service for managing user API keys."""
    
    def __init__(self):
        self.encryption_service = get_encryption_service()
        self.supabase_service = get_supabase_service()
    
    async def _resolve_user_id(self, user_id: str) -> str:
        """
        Resolve user ID to UUID format.
        Handles both UUID and Google sub claim formats.
        
        Args:
            user_id: User UUID or Google sub claim
            
        Returns:
            User UUID string
        """
        # Check if it's already a UUID format
        if '-' in user_id and len(user_id) == 36:
            return user_id
        
        # It's a Google sub claim, look up the UUID
        try:
            result = self.supabase_service.client.table("users")\
                .select("id")\
                .eq("google_sub", user_id)\
                .execute()
            
            if result.data and len(result.data) > 0:
                return result.data[0]["id"]
            
            # User not found, create minimal record
            logger.warning(f"User with Google sub {user_id} not found, creating record")
            user_data = {
                "google_sub": user_id,
                "email": f"user_{user_id}@temp.local",
                "name": f"User {user_id}"
            }
            create_result = self.supabase_service.client.table("users")\
                .insert(user_data)\
                .execute()
            
            if create_result.data and len(create_result.data) > 0:
                return create_result.data[0]["id"]
            
            raise ValueError("Failed to create user record")
            
        except Exception as e:
            logger.error(f"Failed to resolve user ID {user_id}: {str(e)}")
            raise ValueError(f"Failed to resolve user ID: {str(e)}")
    
    async def create_or_update_key(
        self,
        user_id: str,
        provider: str,
        api_key: str,
        priority: int = 0,
        validate: bool = True
    ) -> Dict[str, Any]:
        """
        Create or update user's API key for a provider.
        
        Args:
            user_id: User UUID or Google sub claim
            provider: Provider name
            api_key: Plain API key
            priority: Priority for provider selection
            validate: Whether to validate key before saving
            
        Returns:
            Dict with key metadata
            
        Raises:
            ValueError: If validation fails or provider unsupported
        """
        try:
            # Resolve user ID to UUID
            user_uuid = await self._resolve_user_id(user_id)
            
            # Validate provider
            if not ProviderFactory.is_supported(provider):
                raise ValueError(f"Unsupported provider: {provider}")
            
            # Validate key if requested
            is_validated = False
            validation_error = None
            
            if validate:
                validation_result = await self.validate_key(provider, api_key)
                is_validated = validation_result["is_valid"]
                validation_error = validation_result.get("error")
                
                if not is_validated:
                    logger.warning(f"API key validation failed for {provider}: {validation_error}")
            
            # Encrypt key
            encrypted_key = self.encryption_service.encrypt(api_key)
            
            # Check if key exists
            existing = self.supabase_service.client.table("user_api_keys")\
                .select("id")\
                .eq("user_id", user_uuid)\
                .eq("provider", provider)\
                .execute()
            
            now = datetime.utcnow().isoformat()
            
            if existing.data:
                # Update existing key
                key_id = existing.data[0]["id"]
                update_data = {
                    "encrypted_key": encrypted_key,
                    "priority": priority,
                    "is_validated": is_validated,
                    "validation_error": validation_error,
                    "last_validated_at": now if is_validated else None,
                    "updated_at": now
                }
                
                result = self.supabase_service.client.table("user_api_keys")\
                    .update(update_data)\
                    .eq("id", key_id)\
                    .execute()
                
                logger.info(f"Updated API key for user {user_uuid}, provider {provider}")
            else:
                # Create new key
                insert_data = {
                    "user_id": user_uuid,
                    "provider": provider,
                    "encrypted_key": encrypted_key,
                    "priority": priority,
                    "is_active": True,
                    "is_validated": is_validated,
                    "validation_error": validation_error,
                    "last_validated_at": now if is_validated else None
                }
                
                result = self.supabase_service.client.table("user_api_keys")\
                    .insert(insert_data)\
                    .execute()
                
                logger.info(f"Created API key for user {user_uuid}, provider {provider}")
            
            if not result.data:
                raise ValueError("Failed to save API key")
            
            return self._format_key_response(result.data[0])
            
        except Exception as e:
            logger.error(f"Error creating/updating API key: {str(e)}")
            raise ValueError(f"Failed to save API key: {str(e)}")
    
    async def get_user_keys(self, user_id: str) -> List[Dict[str, Any]]:
        """
        Get all API keys for a user (without decrypted values).
        
        Args:
            user_id: User UUID or Google sub claim
            
        Returns:
            List of key metadata dicts
        """
        try:
            # Resolve user ID to UUID
            logger.info(f"Resolving user ID: {user_id}")
            user_uuid = await self._resolve_user_id(user_id)
            logger.info(f"Resolved to UUID: {user_uuid}")
            
            result = self.supabase_service.client.table("user_api_keys")\
                .select("*")\
                .eq("user_id", user_uuid)\
                .order("priority", desc=True)\
                .order("created_at")\
                .execute()
            
            return [self._format_key_response(key) for key in result.data]
            
        except Exception as e:
            logger.error(f"Error fetching user keys: {str(e)}", exc_info=True)
            raise ValueError(f"Failed to fetch API keys: {str(e)}")
    
    async def get_key(self, user_id: str, key_id: str) -> Optional[Dict[str, Any]]:
        """
        Get specific API key metadata.
        
        Args:
            user_id: User UUID or Google sub claim
            key_id: Key UUID
            
        Returns:
            Key metadata dict or None
        """
        try:
            # Resolve user ID to UUID
            user_uuid = await self._resolve_user_id(user_id)
            
            result = self.supabase_service.client.table("user_api_keys")\
                .select("*")\
                .eq("id", key_id)\
                .eq("user_id", user_uuid)\
                .execute()
            
            if not result.data:
                return None
            
            return self._format_key_response(result.data[0])
            
        except Exception as e:
            logger.error(f"Error fetching key: {str(e)}")
            raise ValueError(f"Failed to fetch API key: {str(e)}")
    
    async def delete_key(self, user_id: str, key_id: str) -> bool:
        """
        Delete user's API key.
        
        Args:
            user_id: User UUID or Google sub claim
            key_id: Key UUID
            
        Returns:
            True if deleted
        """
        try:
            # Resolve user ID to UUID
            user_uuid = await self._resolve_user_id(user_id)
            
            result = self.supabase_service.client.table("user_api_keys")\
                .delete()\
                .eq("id", key_id)\
                .eq("user_id", user_uuid)\
                .execute()
            
            logger.info(f"Deleted API key {key_id} for user {user_uuid}")
            return True
            
        except Exception as e:
            logger.error(f"Error deleting key: {str(e)}")
            raise ValueError(f"Failed to delete API key: {str(e)}")
    
    async def update_key_status(
        self,
        user_id: str,
        key_id: str,
        is_active: Optional[bool] = None,
        priority: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Update key status or priority.
        
        Args:
            user_id: User UUID or Google sub claim
            key_id: Key UUID
            is_active: New active status
            priority: New priority
            
        Returns:
            Updated key metadata
        """
        try:
            # Resolve user ID to UUID
            user_uuid = await self._resolve_user_id(user_id)
            
            update_data = {}
            if is_active is not None:
                update_data["is_active"] = is_active
            if priority is not None:
                update_data["priority"] = priority
            
            if not update_data:
                raise ValueError("No updates provided")
            
            result = self.supabase_service.client.table("user_api_keys")\
                .update(update_data)\
                .eq("id", key_id)\
                .eq("user_id", user_uuid)\
                .execute()
            
            if not result.data:
                raise ValueError("Key not found")
            
            logger.info(f"Updated key {key_id} status for user {user_uuid}")
            return self._format_key_response(result.data[0])
            
        except Exception as e:
            logger.error(f"Error updating key status: {str(e)}")
            raise ValueError(f"Failed to update key: {str(e)}")
    
    async def validate_key(self, provider: str, api_key: str) -> Dict[str, Any]:
        """
        Validate API key with provider.
        
        Args:
            provider: Provider name
            api_key: API key to validate
            
        Returns:
            Dict with validation result
        """
        try:
            provider_instance = ProviderFactory.create_provider(provider, api_key)
            result = await provider_instance.validate_key()
            
            return {
                "is_valid": result["is_valid"],
                "provider": provider,
                "error": result.get("error"),
                "model_info": result.get("model_info")
            }
            
        except Exception as e:
            logger.error(f"Key validation error: {str(e)}")
            return {
                "is_valid": False,
                "provider": provider,
                "error": str(e)
            }
    
    async def get_active_provider(
        self,
        user_id: str,
        preferred_provider: Optional[str] = None
    ) -> Optional[AIProvider]:
        """
        Get active AI provider for user with fallback logic.
        
        Priority:
        1. User's preferred provider (if specified and valid)
        2. User's highest priority validated key
        3. System default (GROQ from env)
        
        Args:
            user_id: User UUID or Google sub claim
            preferred_provider: Optional preferred provider name
            
        Returns:
            AIProvider instance or None
        """
        try:
            # Resolve user ID to UUID
            user_uuid = await self._resolve_user_id(user_id)
            
            # Get user's active keys
            keys = await self.get_user_keys(user_uuid)
            active_keys = [k for k in keys if k["is_active"] and k["is_validated"]]
            
            # Try preferred provider first
            if preferred_provider:
                for key in active_keys:
                    if key["provider"] == preferred_provider:
                        decrypted_key = self.encryption_service.decrypt(key["encrypted_key"])
                        return ProviderFactory.create_provider(preferred_provider, decrypted_key)
            
            # Try highest priority key
            if active_keys:
                key = active_keys[0]  # Already sorted by priority
                decrypted_key = self.encryption_service.decrypt(key["encrypted_key"])
                return ProviderFactory.create_provider(key["provider"], decrypted_key)
            
            # Fallback to system default
            logger.info(f"No user keys found for {user_uuid}, using system default")
            from .provider_service import get_default_provider
            return get_default_provider()
            
        except Exception as e:
            logger.error(f"Error getting active provider: {str(e)}")
            # Fallback to system default on error
            from .provider_service import get_default_provider
            return get_default_provider()
    
    async def log_usage(
        self,
        user_id: str,
        provider: str,
        endpoint: str,
        request_tokens: int = 0,
        response_tokens: int = 0,
        status: str = "success",
        error_message: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> None:
        """
        Log API usage for tracking.
        
        Args:
            user_id: User UUID or Google sub claim
            provider: Provider name
            endpoint: Endpoint name (chat, embedding, rag_query)
            request_tokens: Input tokens
            response_tokens: Output tokens
            status: Request status (success, error, rate_limit)
            error_message: Error message if failed
            metadata: Additional context
        """
        try:
            # Resolve user ID to UUID
            user_uuid = await self._resolve_user_id(user_id)
            
            total_tokens = request_tokens + response_tokens
            
            # Estimate cost (rough estimates, update with actual pricing)
            cost_per_1k_tokens = {
                "groq": 0.0,  # Free tier
                "openai": 0.0015,  # gpt-4o-mini average
                "anthropic": 0.003,  # Claude Sonnet average
                "openrouter": 0.0015,  # Varies by model, using gpt-4o-mini as default
                "google": 0.0,  # Gemini Flash is free tier
            }
            cost_estimate = (total_tokens / 1000) * cost_per_1k_tokens.get(provider, 0.0)
            
            log_data = {
                "user_id": user_uuid,
                "provider": provider,
                "endpoint": endpoint,
                "request_tokens": request_tokens,
                "response_tokens": response_tokens,
                "total_tokens": total_tokens,
                "cost_estimate": cost_estimate,
                "status": status,
                "error_message": error_message,
                "metadata": metadata
            }
            
            self.supabase_service.client.table("api_usage_logs")\
                .insert(log_data)\
                .execute()
            
            logger.debug(f"Logged usage for user {user_uuid}: {provider}/{endpoint}")
            
        except Exception as e:
            # Don't fail the request if logging fails
            logger.error(f"Error logging usage: {str(e)}")
    
    async def get_usage_stats(
        self,
        user_id: str,
        days: int = 30
    ) -> List[Dict[str, Any]]:
        """
        Get usage statistics for user.
        
        Args:
            user_id: User UUID or Google sub claim
            days: Number of days to look back
            
        Returns:
            List of usage stats by provider
        """
        try:
            # Resolve user ID to UUID
            user_uuid = await self._resolve_user_id(user_id)
            
            # Use the SQL function we created
            result = self.supabase_service.client.rpc(
                "get_user_usage_stats",
                {
                    "p_user_id": user_uuid,
                    "p_start_date": (datetime.utcnow() - timedelta(days=days)).isoformat(),
                    "p_end_date": datetime.utcnow().isoformat()
                }
            ).execute()
            
            return result.data or []
            
        except Exception as e:
            logger.error(f"Error fetching usage stats: {str(e)}")
            return []
    
    def _format_key_response(self, key_data: Dict[str, Any]) -> Dict[str, Any]:
        """Format key data for response (mask actual key)."""
        # Decrypt key to create masked version
        try:
            decrypted = self.encryption_service.decrypt(key_data["encrypted_key"])
            if len(decrypted) > 8:
                masked = f"{decrypted[:4]}...{decrypted[-4:]}"
            else:
                masked = "***"
        except:
            masked = "***"
        
        return {
            "id": key_data["id"],
            "provider": key_data["provider"],
            "is_active": key_data["is_active"],
            "is_validated": key_data["is_validated"],
            "validation_error": key_data.get("validation_error"),
            "last_validated_at": key_data.get("last_validated_at"),
            "priority": key_data["priority"],
            "created_at": key_data["created_at"],
            "updated_at": key_data["updated_at"],
            "masked_key": masked,
            "encrypted_key": key_data["encrypted_key"]  # Keep for internal use
        }


# Singleton instance
_api_key_service: Optional[APIKeyService] = None


def get_api_key_service() -> APIKeyService:
    """Get or create API key service singleton."""
    global _api_key_service
    if _api_key_service is None:
        _api_key_service = APIKeyService()
    return _api_key_service
