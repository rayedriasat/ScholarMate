from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class ReadingSessionCreate(BaseModel):
    id: str
    file_id: str
    file_name: str
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_seconds: int = 0
    pages_read: int = 0
    total_pages: Optional[int] = None

class ReadingSessionResponse(BaseModel):
    id: str
    user_id: str
    file_id: str
    file_name: str
    start_time: datetime
    end_time: Optional[datetime]
    duration_seconds: int
    pages_read: int
    total_pages: Optional[int]
    created_at: datetime
    updated_at: datetime

class PageReadCreate(BaseModel):
    id: str
    file_id: str
    page_number: int
    first_read_at: datetime
    last_read_at: datetime
    read_count: int = 1

class PageReadResponse(BaseModel):
    id: str
    user_id: str
    file_id: str
    page_number: int
    first_read_at: datetime
    last_read_at: datetime
    read_count: int
    created_at: datetime
    updated_at: datetime

class AnalyticsSyncRequest(BaseModel):
    sessions: List[ReadingSessionCreate]
    page_reads: List[PageReadCreate]

class AnalyticsStats(BaseModel):
    total_reading_time: int
    total_pages_read: int
    reading_streak: int
    files_read: int
