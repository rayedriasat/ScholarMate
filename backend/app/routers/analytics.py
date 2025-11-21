from fastapi import APIRouter, Depends, HTTPException
from typing import List
from datetime import datetime, timedelta
from ..models.analytics import (
    AnalyticsSyncRequest,
    ReadingSessionResponse,
    PageReadResponse,
    AnalyticsStats,
)
from ..utils.supabase_client import get_supabase_client
from ..utils.auth import get_current_user

router = APIRouter(prefix="/api/analytics", tags=["analytics"])

@router.post("/sync")
async def sync_analytics(
    sync_data: AnalyticsSyncRequest,
    user_id: str = Depends(get_current_user),
):
    """Sync analytics data from client to server"""
    supabase = get_supabase_client()
    
    try:
        # Sync reading sessions
        for session in sync_data.sessions:
            session_data = {
                "id": session.id,
                "user_id": user_id,
                "file_id": session.file_id,
                "file_name": session.file_name,
                "start_time": session.start_time.isoformat(),
                "end_time": session.end_time.isoformat() if session.end_time else None,
                "duration_seconds": session.duration_seconds,
                "pages_read": session.pages_read,
                "total_pages": session.total_pages,
                "updated_at": datetime.utcnow().isoformat(),
            }
            
            # Upsert session
            supabase.table("reading_sessions").upsert(session_data).execute()
        
        # Sync page reads
        for page_read in sync_data.page_reads:
            page_data = {
                "id": page_read.id,
                "user_id": user_id,
                "file_id": page_read.file_id,
                "page_number": page_read.page_number,
                "first_read_at": page_read.first_read_at.isoformat(),
                "last_read_at": page_read.last_read_at.isoformat(),
                "read_count": page_read.read_count,
                "updated_at": datetime.utcnow().isoformat(),
            }
            
            # Upsert page read
            supabase.table("page_read_history").upsert(page_data).execute()
        
        return {"status": "success", "synced_sessions": len(sync_data.sessions), "synced_pages": len(sync_data.page_reads)}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to sync analytics: {str(e)}")

@router.get("/sessions", response_model=List[ReadingSessionResponse])
async def get_reading_sessions(
    limit: int = 50,
    user_id: str = Depends(get_current_user),
):
    """Get user's reading sessions"""
    supabase = get_supabase_client()
    
    try:
        response = (
            supabase.table("reading_sessions")
            .select("*")
            .eq("user_id", user_id)
            .order("start_time", desc=True)
            .limit(limit)
            .execute()
        )
        
        return response.data
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch sessions: {str(e)}")

@router.get("/stats", response_model=AnalyticsStats)
async def get_analytics_stats(
    user_id: str = Depends(get_current_user),
):
    """Get aggregated analytics statistics"""
    supabase = get_supabase_client()
    
    try:
        # Get total reading time
        sessions_response = (
            supabase.table("reading_sessions")
            .select("duration_seconds")
            .eq("user_id", user_id)
            .execute()
        )
        
        total_time = sum(s["duration_seconds"] for s in sessions_response.data)
        
        # Get total unique pages read
        pages_response = (
            supabase.table("page_read_history")
            .select("id")
            .eq("user_id", user_id)
            .execute()
        )
        
        total_pages = len(pages_response.data)
        
        # Get unique files read
        files_response = (
            supabase.table("reading_sessions")
            .select("file_id")
            .eq("user_id", user_id)
            .execute()
        )
        
        unique_files = len(set(f["file_id"] for f in files_response.data))
        
        # Calculate reading streak
        streak = await _calculate_reading_streak(supabase, user_id)
        
        return AnalyticsStats(
            total_reading_time=total_time,
            total_pages_read=total_pages,
            reading_streak=streak,
            files_read=unique_files,
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch stats: {str(e)}")

async def _calculate_reading_streak(supabase, user_id: str) -> int:
    """Calculate consecutive days reading streak"""
    try:
        # Get sessions from last year
        one_year_ago = datetime.utcnow() - timedelta(days=365)
        
        response = (
            supabase.table("reading_sessions")
            .select("start_time")
            .eq("user_id", user_id)
            .gte("start_time", one_year_ago.isoformat())
            .execute()
        )
        
        if not response.data:
            return 0
        
        # Extract unique dates
        dates = set()
        for session in response.data:
            date = datetime.fromisoformat(session["start_time"]).date()
            dates.add(date)
        
        # Calculate streak
        sorted_dates = sorted(dates, reverse=True)
        streak = 0
        check_date = datetime.utcnow().date()
        
        for _ in range(365):
            if check_date in sorted_dates:
                streak += 1
                check_date -= timedelta(days=1)
            else:
                break
        
        return streak
    
    except Exception:
        return 0
