"""
Backend Drive Service for fetching files from Google Drive.
Receives access tokens from frontend with each request.
"""

import logging
from typing import Dict, Any
import requests

logger = logging.getLogger(__name__)


class BackendDriveService:
    """Service for accessing user's Google Drive files from backend.
    
    Note: This service does NOT store or refresh tokens. The frontend
    manages tokens using platform-specific secure storage and passes
    fresh access tokens with each request.
    """
    
    def __init__(self):
        """Initialize Drive service."""
        logger.info("Backend Drive service initialized")
    

    
    def get_file_bytes(
        self,
        file_id: str,
        access_token: str
    ) -> bytes:
        """
        Fetch file bytes from Google Drive using provided access token.
        
        Args:
            file_id: Google Drive file ID
            access_token: Valid access token from frontend
            
        Returns:
            File bytes
            
        Raises:
            ValueError: If file cannot be fetched
        """
        download_url = f"https://www.googleapis.com/drive/v3/files/{file_id}?alt=media"
        headers = {
            "Authorization": f"Bearer {access_token}"
        }
        
        try:
            response = requests.get(download_url, headers=headers, timeout=30)
            response.raise_for_status()
            
            file_bytes = response.content
            logger.info(f"Successfully fetched file {file_id} ({len(file_bytes)} bytes)")
            
            return file_bytes
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch file {file_id}: {str(e)}")
            if hasattr(e, 'response') and e.response is not None:
                if e.response.status_code == 401:
                    raise ValueError("Access token expired or invalid. Please refresh token in app and retry.")
                elif e.response.status_code == 404:
                    raise ValueError(f"File {file_id} not found in Google Drive")
                elif e.response.status_code == 403:
                    raise ValueError(f"Access denied to file {file_id}. Check permissions.")
            raise ValueError(f"Failed to fetch file from Drive: {str(e)}")
    
    def get_file_metadata(
        self,
        file_id: str,
        access_token: str
    ) -> Dict[str, Any]:
        """
        Get file metadata from Google Drive using provided access token.
        
        Args:
            file_id: Google Drive file ID
            access_token: Valid access token from frontend
            
        Returns:
            File metadata dict
            
        Raises:
            ValueError: If metadata cannot be fetched
        """
        metadata_url = f"https://www.googleapis.com/drive/v3/files/{file_id}"
        params = {
            "fields": "id,name,mimeType,size,createdTime,modifiedTime"
        }
        headers = {
            "Authorization": f"Bearer {access_token}"
        }
        
        try:
            response = requests.get(metadata_url, params=params, headers=headers, timeout=10)
            response.raise_for_status()
            
            metadata = response.json()
            logger.info(f"Successfully fetched metadata for file {file_id}")
            
            return metadata
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch metadata for file {file_id}: {str(e)}")
            if hasattr(e, 'response') and e.response is not None:
                if e.response.status_code == 401:
                    raise ValueError("Access token expired or invalid. Please refresh token in app and retry.")
                elif e.response.status_code == 404:
                    raise ValueError(f"File {file_id} not found in Google Drive")
            raise ValueError(f"Failed to fetch file metadata: {str(e)}")


# Singleton instance
_drive_service: BackendDriveService | None = None


def get_drive_service() -> BackendDriveService:
    """Get or create Backend Drive service singleton."""
    global _drive_service
    if _drive_service is None:
        _drive_service = BackendDriveService()
    return _drive_service
