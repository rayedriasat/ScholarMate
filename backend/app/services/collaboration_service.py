"""Collaboration service for real-time PDF sessions"""
import os
import secrets
from typing import Optional, Dict, List, Any
from datetime import datetime, timedelta
from uuid import UUID
from ..services.supabase_service import get_supabase_service
from ..utils.logging_config import get_logger

logger = get_logger(__name__)

# User color palette for cursor identification
USER_COLORS = [
    "#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8",
    "#F7DC6F", "#BB8FCE", "#85C1E2", "#F8B739", "#52B788"
]


class CollaborationService:
    """Service for managing real-time collaboration sessions"""
    
    def __init__(self):
        self.supabase = get_supabase_service()
        self.backend_url = os.getenv("BACKEND_URL", "http://localhost:8000")
    
    def _assign_user_color(self, existing_colors: List[str]) -> str:
        """Assign unique color to user"""
        available = [c for c in USER_COLORS if c not in existing_colors]
        return available[0] if available else secrets.choice(USER_COLORS)
    
    async def create_session(
        self,
        file_id: str,
        file_name: str,
        owner_id: str,
        owner_name: str,
        owner_email: str,
        default_role: str = "editor"
    ) -> Dict[str, Any]:
        """
        Create new collaboration session
        
        Args:
            file_id: Google Drive file ID
            file_name: PDF file name
            owner_id: Session owner user ID
            owner_name: Owner display name
            owner_email: Owner email
            default_role: Default role for joiners
            
        Returns:
            Session data with share link
        """
        try:
            # Generate unique session ID
            session_id = secrets.token_urlsafe(16)
            
            # Create session in database
            session_data = {
                "session_id": session_id,
                "file_id": file_id,
                "file_name": file_name,
                "owner_id": owner_id,
                "default_role": default_role,
                "expires_at": (datetime.utcnow() + timedelta(days=7)).isoformat()
            }
            
            response = self.supabase.client.table("collaboration_sessions").insert(session_data).execute()
            
            # Add owner as first participant
            owner_color = USER_COLORS[0]
            participant_data = {
                "session_id": session_id,
                "user_id": owner_id,
                "user_name": owner_name,
                "user_email": owner_email,
                "user_color": owner_color,
                "role": "owner"
            }
            
            self.supabase.client.table("session_participants").insert(participant_data).execute()
            
            # Generate share link
            share_link = f"{self.backend_url}/collaborate/{session_id}"
            
            logger.info(f"Created collaboration session {session_id} for file {file_id}")
            
            return {
                "session_id": session_id,
                "file_id": str(file_id),
                "file_name": file_name,
                "owner_id": owner_id,
                "share_link": share_link,
                "participants": [participant_data],
                "created_at": datetime.utcnow().isoformat(),
                "expires_at": session_data["expires_at"]
            }
            
        except Exception as e:
            logger.error(f"Error creating collaboration session: {e}")
            raise
    
    async def join_session(
        self,
        session_id: str,
        user_id: str,
        user_name: str,
        user_email: str
    ) -> Dict[str, Any]:
        """
        Join existing collaboration session
        
        Args:
            session_id: Session ID
            user_id: User ID
            user_name: User display name
            user_email: User email
            
        Returns:
            Session data with participants
        """
        try:
            # Get session
            session_response = self.supabase.client.table("collaboration_sessions").select("*").eq("session_id", session_id).execute()
            
            if not session_response.data:
                raise ValueError(f"Session {session_id} not found")
            
            session = session_response.data[0]
            
            # Check if session expired
            if session.get("expires_at"):
                expires_at = datetime.fromisoformat(session["expires_at"].replace("Z", "+00:00"))
                now = datetime.now(expires_at.tzinfo)  # Use same timezone
                if expires_at < now:
                    raise ValueError("Session has expired")
            
            # Get existing participants
            participants_response = self.supabase.client.table("session_participants").select("*").eq("session_id", session_id).execute()
            
            existing_participants = participants_response.data or []
            
            # Check if user already in session
            existing = next((p for p in existing_participants if p["user_id"] == user_id), None)
            
            if existing:
                # Update last_seen
                self.supabase.client.table("session_participants").update({
                    "last_seen": datetime.utcnow().isoformat()
                }).eq("id", existing["id"]).execute()
                
                logger.info(f"User {user_id} rejoined session {session_id}")
            else:
                # Assign color
                existing_colors = [p["user_color"] for p in existing_participants]
                user_color = self._assign_user_color(existing_colors)
                
                # Add participant
                participant_data = {
                    "session_id": session_id,
                    "user_id": user_id,
                    "user_name": user_name,
                    "user_email": user_email,
                    "user_color": user_color,
                    "role": session["default_role"]
                }
                
                self.supabase.client.table("session_participants").insert(participant_data).execute()
                existing_participants.append(participant_data)
                
                logger.info(f"User {user_id} joined session {session_id}")
            
            # Get updated participants
            participants_response = self.supabase.client.table("session_participants").select("*").eq("session_id", session_id).execute()
            
            # Generate share link
            share_link = f"{self.backend_url}/collaborate/{session_id}"
            
            return {
                "session_id": session_id,
                "file_id": session["file_id"],
                "file_name": session["file_name"],
                "owner_id": session["owner_id"],
                "share_link": share_link,
                "participants": participants_response.data,
                "created_at": session["created_at"],
                "expires_at": session.get("expires_at")
            }
            
        except Exception as e:
            logger.error(f"Error joining session {session_id}: {e}")
            raise
    
    async def leave_session(self, session_id: str, user_id: str) -> None:
        """Remove user from session"""
        try:
            self.supabase.client.table("session_participants").delete().eq("session_id", session_id).eq("user_id", user_id).execute()
            logger.info(f"User {user_id} left session {session_id}")
        except Exception as e:
            logger.error(f"Error leaving session: {e}")
            raise
    
    async def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get session details"""
        try:
            session_response = self.supabase.client.table("collaboration_sessions").select("*").eq("session_id", session_id).execute()
            
            if not session_response.data:
                return None
            
            session = session_response.data[0]
            
            # Get participants
            participants_response = self.supabase.client.table("session_participants").select("*").eq("session_id", session_id).execute()
            
            # Generate share link
            share_link = f"{self.backend_url}/collaborate/{session_id}"
            
            return {
                **session,
                "share_link": share_link,
                "participants": participants_response.data or []
            }
        except Exception as e:
            logger.error(f"Error getting session {session_id}: {e}")
            raise
    
    async def update_cursor(
        self,
        session_id: str,
        user_id: str,
        cursor_data: Optional[Dict[str, Any]]
    ) -> None:
        """Update user cursor position"""
        try:
            update_data = {
                "cursor_position": cursor_data,
                "last_seen": datetime.utcnow().isoformat()
            }
            
            self.supabase.client.table("session_participants").update(update_data).eq("session_id", session_id).eq("user_id", user_id).execute()
            
        except Exception as e:
            logger.error(f"Error updating cursor: {e}")
            raise


# Singleton
_collaboration_service: Optional[CollaborationService] = None


def get_collaboration_service() -> CollaborationService:
    """Get collaboration service singleton"""
    global _collaboration_service
    if _collaboration_service is None:
        _collaboration_service = CollaborationService()
    return _collaboration_service


    async def add_annotation(
        self,
        session_id: str,
        annotation: Dict[str, Any]
    ) -> None:
        """Add annotation to session"""
        try:
            annotation_data = {
                "session_id": session_id,
                "annotation_id": annotation.get("id"),
                "user_id": annotation.get("user_id"),
                "user_name": annotation.get("user_name"),
                "user_color": annotation.get("user_color"),
                "annotation_type": annotation.get("annotation_type"),
                "page_number": annotation.get("page_number"),
                "bounds": annotation.get("position_data"),
                "color": annotation.get("color"),
                "opacity": annotation.get("opacity", 1.0),
                "text_content": annotation.get("content"),
            }
            
            self.supabase.client.table("collaboration_annotations").insert(annotation_data).execute()
            logger.info(f"Added annotation {annotation.get('id')} to session {session_id}")
            
        except Exception as e:
            logger.error(f"Error adding annotation: {e}")
            raise
    
    async def get_annotations(self, session_id: str) -> List[Dict[str, Any]]:
        """Get all annotations for a session"""
        try:
            response = self.supabase.client.table("collaboration_annotations").select("*").eq("session_id", session_id).execute()
            return response.data or []
        except Exception as e:
            logger.error(f"Error getting annotations: {e}")
            raise
    
    async def delete_annotation(
        self,
        session_id: str,
        annotation_id: str,
        user_id: str
    ) -> None:
        """Delete annotation from session"""
        try:
            self.supabase.client.table("collaboration_annotations").delete().eq("session_id", session_id).eq("annotation_id", annotation_id).eq("user_id", user_id).execute()
            logger.info(f"Deleted annotation {annotation_id} from session {session_id}")
        except Exception as e:
            logger.error(f"Error deleting annotation: {e}")
            raise
