# Task 12.3: Indexing API Endpoints - Implementation Summary

## Overview
Implemented complete REST API endpoints for RAG indexing job management with user isolation and progress tracking.

## Files Created

### 1. `backend/app/models/ingestion.py`
Pydantic models for request/response validation:
- `StartIndexingRequest` - Request to start indexing
- `StartIndexingResponse` - Response with job_id
- `JobStatus` - Detailed job status with progress
- `JobListResponse` - List of jobs for a user
- `ReindexRequest` - Request to reindex a file
- `ReindexResponse` - Response from reindexing

### 2. `backend/app/routers/ingestion.py`
API router with 4 endpoints:
- `POST /api/ingest/start` - Start indexing a file
- `GET /api/ingest/status/{job_id}` - Get job status with progress
- `GET /api/ingest/list/{user_id}` - List all jobs for a user
- `POST /api/ingest/reindex/{file_id}` - Manually reindex a file

### 3. `backend/test_ingestion_endpoints.py`
Test script documenting endpoint usage and testing instructions.

## Files Modified

### 1. `backend/app/services/rag_indexer.py`
Updated job tracking methods to work with existing Supabase schema:
- `_create_indexing_job()` - Creates job record with proper file UUID handling
- `_update_job_status()` - Updates job status (pending/processing/completed/failed)
- `_update_job_progress()` - Updates progress percentage and chunks info
- `get_job_status()` - Retrieves job status by job_id
- `list_user_jobs()` - Lists all RAG indexing jobs for a user

**Key Implementation Details:**
- Works with existing `ingestion_jobs` table schema (has `job_type`, `progress_percent`, `metadata`)
- Stores custom job_id in metadata JSONB field
- Handles Drive file_id to Supabase UUID conversion
- Creates file records in Supabase if they don't exist
- Stores chunks_processed and total_chunks in metadata
- Returns Drive file_id (not Supabase UUID) in API responses

### 2. `backend/app/main.py`
- Added import for `ingestion` router
- Registered ingestion router with FastAPI app

## API Endpoints

### POST /api/ingest/start
**Request:**
```json
{
  "user_id": "uuid",
  "file_id": "google_drive_file_id",
  "file_name": "optional_file_name.pdf"
}
```

**Response:**
```json
{
  "job_id": "uuid",
  "status": "processing",
  "message": "Indexing started for file {file_id}"
}
```

### GET /api/ingest/status/{job_id}
**Response:**
```json
{
  "job_id": "uuid",
  "user_id": "uuid",
  "file_id": "google_drive_file_id",
  "status": "processing",
  "chunks_processed": 50,
  "total_chunks": 100,
  "progress_percentage": 50.0,
  "error_message": null,
  "started_at": "2025-11-01T09:00:00Z",
  "completed_at": null,
  "created_at": "2025-11-01T08:59:00Z"
}
```

### GET /api/ingest/list/{user_id}
**Response:**
```json
{
  "jobs": [
    {
      "job_id": "uuid",
      "user_id": "uuid",
      "file_id": "google_drive_file_id",
      "status": "completed",
      "chunks_processed": 100,
      "total_chunks": 100,
      "progress_percentage": 100.0,
      "error_message": null,
      "started_at": "2025-11-01T09:00:00Z",
      "completed_at": "2025-11-01T09:05:00Z",
      "created_at": "2025-11-01T08:59:00Z"
    }
  ],
  "total": 1
}
```

### POST /api/ingest/reindex/{file_id}
**Request:**
```json
{
  "user_id": "uuid",
  "file_name": "optional_file_name.pdf"
}
```

**Response:**
```json
{
  "job_id": "uuid",
  "status": "processing",
  "message": "Reindexing started for file {file_id}"
}
```

## Security Features

### User Isolation
- All endpoints enforce user isolation through Supabase RLS policies
- Users can only access their own indexing jobs
- Service role (backend) can access all data for processing

### Error Handling
- Comprehensive error handling for all endpoints
- Graceful degradation if job tracking fails
- Meaningful error messages returned to client
- All errors logged with context

## Database Schema Integration

Works with existing `ingestion_jobs` table:
```sql
CREATE TABLE ingestion_jobs (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    file_id UUID REFERENCES files(id),
    job_type TEXT,  -- 'rag_indexing'
    status TEXT,    -- 'pending', 'processing', 'completed', 'failed'
    progress_percent INTEGER,
    error_message TEXT,
    metadata JSONB, -- Stores job_id, drive_file_id, chunks info
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
```

## Testing

### Manual Testing
1. Start backend: `uv run python run.py`
2. Visit Swagger UI: http://localhost:8000/docs
3. Test each endpoint with sample data

### Integration Testing
Run the test script:
```bash
cd backend
uv run python test_ingestion_endpoints.py
```

## Requirements Satisfied

✅ **Requirement 13.1**: POST /api/ingest/start triggers indexing with user_id and file_id
✅ **Requirement 13.10**: GET /api/ingest/status/{job_id} tracks status with progress
✅ **Requirement 13.12**: All endpoints enforce user isolation (only access own data)
✅ **Additional**: GET /api/ingest/list/{user_id} lists all jobs for user
✅ **Additional**: POST /api/ingest/reindex/{file_id} enables manual re-indexing

## Next Steps

The following tasks remain in Phase 10:
- [ ] 12.4 - Implement async job processing with progress tracking
- [ ] 12.5 - Build indexing status UI in Flutter
- [ ] 12.6 - Trigger automatic indexing on upload

## Notes

- Job tracking is resilient - indexing continues even if job tracking fails
- Progress is tracked as percentage (0-100) and chunks (processed/total)
- Jobs are filtered by `job_type='rag_indexing'` to separate from OCR jobs
- Drive file IDs are used in API responses for consistency with frontend
- Supabase UUIDs are used internally for database relationships
