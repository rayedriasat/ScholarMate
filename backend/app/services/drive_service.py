"""
Backend Drive Service for fetching files from Google Drive.
Uses user's encrypted refresh tokens to access their Drive files.
"""

import os
import logging
from typing import Optional, Dict, Any
import requests
from .encryption_service import get_encryption_service
from .supabase_service import get_supabase_service

logger = logging.getLogger(__name__)


class BackendDriveService:
    """Service for accessing user's Google Drive files from backend."""
    
    def __init__(self):
        """Initialize Drive service with Google OAuth credentials."""
        self.client_id = os.getenv("GOOGLE_CLIENT_ID")
        self.client_secret = os.getenv("GOOGLE_CLIENT_SECRET")
        
        if not self.client_id or not self.client_secret:
            raise ValueError("GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET must be set")
        
        self.encryption_service = get_encryption_service()
        self.supabase_service = get_supabase_service()
        
        logger.info("Backend Drive service initialized")
    
    async def refresh_access_token(self, user_id: str) -> str:
        """
        Refresh user's access token using stored refresh token.
        
        Args:
            user_id: User UUID
            
        Returns:
            New access token
            
        Raises:
            ValueError: If refresh token not found or refresh fails
        """
        # Get encrypted refresh token from database
        encrypted_refresh_token = await self.supabase_service.get_encrypted_token(
            user_id=user_id,
            token_type="refresh_token"
        )
        
        if not encrypted_refresh_token:
            raise ValueError(f"No refresh token found for user {user_id}")
        
        # Decrypt refresh token
        refresh_token = self.encryption_service.decrypt(encrypted_refresh_token)
        
        # Exchange refresh token for new access token
        token_url = "https://oauth2.googleapis.com/token"
        data = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token"
        }
        
        try:
            response = requests.post(token_url, data=data)
            response.raise_for_status()
            
            token_data = response.json()
            access_token = token_data.get("access_token")
            
            if not access_token:
                raise ValueError("No access token in refresh response")
            
            # Store new access token (encrypted)
            encrypted_access_token = self.encryption_service.encrypt(access_token)
            await self.supabase_service.store_encrypted_token(
                user_id=user_id,
                token_type="access_token",
                encrypted_token=encrypted_access_token
            )
            
            logger.info(f"Successfully refreshed access token for user {user_id}")
            return access_token
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to refresh access token for user {user_id}: {str(e)}")
            raise ValueError(f"Failed to refresh access token: {str(e)}")
    
    async def get_access_token(self, user_id: str) -> str:
        """
        Get valid access token for user, refreshing if necessary.
        
        Args:
            user_id: User UUID
            
        Returns:
            Valid access token
        """
        # Try to get existing access token
        encrypted_access_token = await self.supabase_service.get_encrypted_token(
            user_id=user_id,
            token_type="access_token"
        )
        
        if encrypted_access_token:
            access_token = self.encryption_service.decrypt(encrypted_access_token)
            
            # TODO: Check if token is expired before using
            # For now, we'll try to use it and refresh on failure
            return access_token
        
        # No access token found, refresh it
        return await self.refresh_access_token(user_id)
    
    async def get_file_bytes(
        self,
        file_id: str,
        user_id: str,
        retry_on_auth_error: bool = True
    ) -> bytes:
        """
        Fetch file bytes from Google Drive.
        
        Args:
            file_id: Google Drive file ID
            user_id: User UUID
            retry_on_auth_error: Whether to retry with refreshed token on auth error
            
        Returns:
            File bytes
            
        Raises:
            ValueError: If file cannot be fetched
        """
        access_token = await self.get_access_token(user_id)
        
        # Download file from Google Drive
        download_url = f"https://www.googleapis.com/drive/v3/files/{file_id}?alt=media"
        headers = {
            "Authorization": f"Bearer {access_token}"
        }
        
        try:
            response = requests.get(download_url, headers=headers)
            
            # If unauthorized and retry is enabled, refresh token and try again
            if response.status_code == 401 and retry_on_auth_error:
                logger.info(f"Access token expired for user {user_id}, refreshing...")
                access_token = await self.refresh_access_token(user_id)
                headers["Authorization"] = f"Bearer {access_token}"
                response = requests.get(download_url, headers=headers)
            
            response.raise_for_status()
            
            file_bytes = response.content
            logger.info(f"Successfully fetched file {file_id} ({len(file_bytes)} bytes) for user {user_id}")
            
            return file_bytes
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch file {file_id} for user {user_id}: {str(e)}")
            raise ValueError(f"Failed to fetch file from Drive: {str(e)}")
    
    async def get_file_metadata(
        self,
        file_id: str,
        user_id: str,
        retry_on_auth_error: bool = True
    ) -> Dict[str, Any]:
        """
        Get file metadata from Google Drive.
        
        Args:
            file_id: Google Drive file ID
            user_id: User UUID
            retry_on_auth_error: Whether to retry with refreshed token on auth error
            
        Returns:
            File metadata dict
            
        Raises:
            ValueError: If metadata cannot be fetched
        """
        access_token = await self.get_access_token(user_id)
        
        # Get file metadata
        metadata_url = f"https://www.googleapis.com/drive/v3/files/{file_id}"
        params = {
            "fields": "id,name,mimeType,size,createdTime,modifiedTime"
        }
        headers = {
            "Authorization": f"Bearer {access_token}"
        }
        
        try:
            response = requests.get(metadata_url, params=params, headers=headers)
            
            # If unauthorized and retry is enabled, refresh token and try again
            if response.status_code == 401 and retry_on_auth_error:
                logger.info(f"Access token expired for user {user_id}, refreshing...")
                access_token = await self.refresh_access_token(user_id)
                headers["Authorization"] = f"Bearer {access_token}"
                response = requests.get(metadata_url, params=params, headers=headers)
            
            response.raise_for_status()
            
            metadata = response.json()
            logger.info(f"Successfully fetched metadata for file {file_id}")
            
            return metadata
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch metadata for file {file_id}: {str(e)}")
            raise ValueError(f"Failed to fetch file metadata: {str(e)}")


# Singleton instance
_drive_service: Optional[BackendDriveService] = None


def get_drive_service() -> BackendDriveService:
    """Get or create Backend Drive service singleton."""
    global _drive_service
    if _drive_service is None:
        _drive_service = BackendDriveService()
    return _drive_service
