"""Supabase database service"""
import os
from typing import Optional, Dict, Any
from supabase import create_client, Client
from datetime import datetime


class SupabaseService:
    """Service for interacting with Supabase database"""
    
    def __init__(self):
        """Initialize Supabase client"""
        supabase_url = os.getenv("SUPABASE_URL")
        supabase_key = os.getenv("SUPABASE_SERVICE_KEY")  # Use service key for backend
        
        if not supabase_url or not supabase_key:
            raise ValueError("SUPABASE_URL and SUPABASE_SERVICE_KEY must be set")
        
        self.client: Client = create_client(supabase_url, supabase_key)
    
    async def get_or_create_user(
        self,
        google_sub: str,
        email: str,
        name: Optional[str] = None,
        picture_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get existing user or create new user
        
        Args:
            google_sub: Google OAuth sub claim (unique user ID)
            email: User email
            name: User display name
            picture_url: User profile picture URL
            
        Returns:
            User record from database
        """
        # Try to get existing user
        response = self.client.table("users").select("*").eq("google_sub", google_sub).execute()
        
        if response.data and len(response.data) > 0:
            # Update existing user
            user = response.data[0]
            update_data = {
                "email": email,
                "updated_at": datetime.utcnow().isoformat()
            }
            if name:
                update_data["name"] = name
            if picture_url:
                update_data["picture_url"] = picture_url
            
            response = self.client.table("users").update(update_data).eq("id", user["id"]).execute()
            return response.data[0]
        else:
            # Create new user
            user_data = {
                "google_sub": google_sub,
                "email": email,
                "name": name,
                "picture_url": picture_url
            }
            response = self.client.table("users").insert(user_data).execute()
            return response.data[0]
    
    async def store_encrypted_token(
        self,
        user_id: str,
        token_type: str,
        encrypted_token: str
    ) -> Dict[str, Any]:
        """
        Store encrypted token for user
        
        Args:
            user_id: User UUID
            token_type: Type of token (e.g., 'access_token', 'refresh_token', 'id_token')
            encrypted_token: Encrypted token string
            
        Returns:
            Token record from database
        """
        # Check if token already exists
        response = self.client.table("encrypted_tokens").select("*").eq("user_id", user_id).eq("token_type", token_type).execute()
        
        if response.data and len(response.data) > 0:
            # Update existing token
            token_id = response.data[0]["id"]
            update_data = {
                "encrypted_token": encrypted_token,
                "updated_at": datetime.utcnow().isoformat()
            }
            response = self.client.table("encrypted_tokens").update(update_data).eq("id", token_id).execute()
            return response.data[0]
        else:
            # Insert new token
            token_data = {
                "user_id": user_id,
                "token_type": token_type,
                "encrypted_token": encrypted_token
            }
            response = self.client.table("encrypted_tokens").insert(token_data).execute()
            return response.data[0]
    
    async def get_user_by_google_sub(self, google_sub: str) -> Optional[Dict[str, Any]]:
        """
        Get user by Google sub claim
        
        Args:
            google_sub: Google OAuth sub claim (unique user ID)
            
        Returns:
            User record or None if not found
        """
        response = self.client.table("users").select("*").eq("google_sub", google_sub).execute()
        
        if response.data and len(response.data) > 0:
            return response.data[0]
        return None
    
    async def get_encrypted_token(
        self,
        user_id: str,
        token_type: str
    ) -> Optional[str]:
        """
        Get encrypted token for user
        
        Args:
            user_id: User UUID or Google sub
            token_type: Type of token
            
        Returns:
            Encrypted token string or None if not found
        """
        # Check if user_id is a UUID or Google sub
        # If it's not a valid UUID format, treat it as Google sub
        actual_user_id = user_id
        
        # Simple check: UUIDs contain hyphens, Google subs don't
        if '-' not in user_id:
            # This is likely a Google sub, look up the UUID
            user = await self.get_user_by_google_sub(user_id)
            if not user:
                return None
            actual_user_id = user["id"]
        
        response = self.client.table("encrypted_tokens").select("encrypted_token").eq("user_id", actual_user_id).eq("token_type", token_type).execute()
        
        if response.data and len(response.data) > 0:
            return response.data[0]["encrypted_token"]
        return None
    
    async def delete_user_tokens(self, user_id: str) -> None:
        """
        Delete all tokens for a user
        
        Args:
            user_id: User UUID
        """
        self.client.table("encrypted_tokens").delete().eq("user_id", user_id).execute()


# Singleton instance
_supabase_service: Optional[SupabaseService] = None


def get_supabase_service() -> SupabaseService:
    """Get or create Supabase service singleton"""
    global _supabase_service
    if _supabase_service is None:
        _supabase_service = SupabaseService()
    return _supabase_service
