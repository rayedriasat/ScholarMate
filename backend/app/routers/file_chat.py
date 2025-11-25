"""File chat API endpoints"""
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from ..services.supabase_service import get_supabase_service, SupabaseService

router = APIRouter(prefix="/api/file-chat", tags=["file-chat"])


class CreateThreadRequest(BaseModel):
    """Request to create a chat thread"""
    file_id: str


class SendMessageRequest(BaseModel):
    """Request to send a message"""
    thread_id: str
    file_id: str
    user_id: str
    user_name: str
    user_photo_url: Optional[str] = None
    content: str


class MessageResponse(BaseModel):
    """Chat message response"""
    id: str
    thread_id: str
    file_id: str
    user_id: str
    user_name: str
    user_photo_url: Optional[str]
    content: str
    timestamp: str
    

class ThreadResponse(BaseModel):
    """Chat thread response"""
    id: str
    file_id: str
    created_at: str
    updated_at: str
    message_count: int


@router.post("/threads", response_model=ThreadResponse)
async def create_thread(
    request: CreateThreadRequest,
    supabase: SupabaseService = Depends(get_supabase_service),
):
    """Create a new chat thread for a file"""
    try:
        # Check if thread already exists
        response = supabase.client.table("file_chat_threads").select("*").eq(
            "file_id", request.file_id
        ).execute()
        
        if response.data and len(response.data) > 0:
            return ThreadResponse(**response.data[0])
        
        # Create new thread
        import uuid
        thread_data = {
            "id": str(uuid.uuid4()),
            "file_id": request.file_id,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
            "message_count": 0,
        }
        
        response = supabase.client.table("file_chat_threads").insert(thread_data).execute()
        
        if not response.data:
            raise HTTPException(status_code=500, detail="Failed to create thread")
        
        return ThreadResponse(**response.data[0])
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/threads/{file_id}", response_model=Optional[ThreadResponse])
async def get_thread(
    file_id: str,
    supabase: SupabaseService = Depends(get_supabase_service),
):
    """Get chat thread for a file"""
    try:
        response = supabase.client.table("file_chat_threads").select("*").eq(
            "file_id", file_id
        ).execute()
        
        if not response.data or len(response.data) == 0:
            return None
        
        return ThreadResponse(**response.data[0])
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/messages", response_model=MessageResponse)
async def send_message(
    request: SendMessageRequest,
    supabase: SupabaseService = Depends(get_supabase_service),
):
    """Send a message in a chat thread"""
    try:
        import uuid
        message_data = {
            "id": str(uuid.uuid4()),
            "thread_id": request.thread_id,
            "file_id": request.file_id,
            "user_id": request.user_id,
            "user_name": request.user_name,
            "user_photo_url": request.user_photo_url,
            "content": request.content,
            "timestamp": datetime.utcnow().isoformat(),
        }
        
        response = supabase.client.table("file_chat_messages").insert(message_data).execute()
        
        if not response.data:
            raise HTTPException(status_code=500, detail="Failed to send message")
        
        # Update thread
        supabase.client.table("file_chat_threads").update({
            "updated_at": datetime.utcnow().isoformat(),
        }).eq("id", request.thread_id).execute()
        
        return MessageResponse(**response.data[0])
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/messages/{file_id}", response_model=List[MessageResponse])
async def get_messages(
    file_id: str,
    supabase: SupabaseService = Depends(get_supabase_service),
):
    """Get all messages for a file"""
    try:
        response = supabase.client.table("file_chat_messages").select("*").eq(
            "file_id", file_id
        ).order("timestamp", desc=False).execute()
        
        if not response.data:
            return []
        
        return [MessageResponse(**msg) for msg in response.data]
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/access/{file_id}/{user_id}")
async def check_access(
    file_id: str,
    user_id: str,
    supabase: SupabaseService = Depends(get_supabase_service),
):
    """Check if user has access to file chat"""
    try:
        # Check if user has access via file_shares table
        response = supabase.client.table("file_shares").select("id").eq(
            "file_id", file_id
        ).eq("shared_with_user_id", user_id).execute()
        
        has_access = response.data and len(response.data) > 0
        
        return {"has_access": has_access}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
