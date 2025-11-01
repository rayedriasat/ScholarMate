# Task 12.4: Async Job Processing with Progress Tracking

## Implementation Summary

Successfully implemented async job processing with progress tracking, retry logic with exponential backoff, and comprehensive error handling for the RAG indexing system.

## Changes Made

### 1. RAG Indexer Service (`app/services/rag_indexer.py`)

**Added Configuration Constants:**
```python
MAX_RETRIES = 3
INITIAL_RETRY_DELAY = 1  # seconds
MAX_RETRY_DELAY = 60  # seconds
```

**Refactored `index_file()` Method:**
- Now only creates the job record with "pending" status
- Returns immediately without blocking
- Actual processing happens in background via `process_indexing_job()`

**New `process_indexing_job()` Method:**
- Runs asynchronously in the background
- Handles all heavy lifting (file fetching, text extraction, embedding generation)
- Implements retry logic with exponential backoff
- Updates job status throughout the process
- Tracks progress with chunks_processed/total_chunks

**Enhanced `_create_indexing_job()` Method:**
- Added `file_name` parameter
- Stores retry metadata in job record
- Raises errors for critical failures (job creation)

**New `_update_job_retry_info()` Method:**
- Tracks retry attempts in job metadata
- Stores last error message for debugging
- Updates retry_count for monitoring

**Retry Logic Features:**
- Exponential backoff: delay = min(INITIAL_RETRY_DELAY * (2 ** retry_count), MAX_RETRY_DELAY)
- Maximum 3 retries (4 total attempts)
- Automatic retry on transient errors
- Marks job as "failed" after max retries exceeded

### 2. Ingestion Router (`app/routers/ingestion.py`)

**Updated `start_indexing()` Endpoint:**
- Added `BackgroundTasks` parameter
- Creates job record immediately
- Schedules background processing via `background_tasks.add_task()`
- Returns "pending" status instead of "processing"
- Non-blocking - API responds immediately

**Updated `reindex_file()` Endpoint:**
- Added `BackgroundTasks` parameter
- Deletes old embeddings synchronously
- Creates new job and schedules background processing
- Returns "pending" status

### 3. Test Suite (`test_async_job_processing.py`)

Created comprehensive test suite with 6 tests:

1. **test_create_indexing_job**: Verifies job creation with pending status
2. **test_process_indexing_job_success**: Tests successful background processing
3. **test_process_indexing_job_retry_on_failure**: Tests retry logic on transient errors
4. **test_process_indexing_job_max_retries_exceeded**: Tests failure after max retries
5. **test_job_progress_tracking**: Verifies progress updates with chunk counts
6. **test_exponential_backoff_delay**: Validates exponential backoff delays

All tests use proper mocking to avoid external dependencies.

## Database Schema

The existing `ingestion_jobs` table already supports all required fields:

```sql
CREATE TABLE ingestion_jobs (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    file_id UUID REFERENCES files(id),
    job_type TEXT NOT NULL,
    status TEXT NOT NULL,  -- 'pending', 'processing', 'completed', 'failed'
    progress_percent INTEGER DEFAULT 0,
    error_message TEXT,
    metadata JSONB,  -- Stores: job_id, drive_file_id, chunks_processed, total_chunks, retry_count, last_error
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Job Lifecycle

1. **Pending**: Job created, waiting for background processing
2. **Processing**: Background task started, fetching file and extracting text
3. **Completed**: All chunks indexed successfully
4. **Failed**: Max retries exceeded or critical error occurred

## Progress Tracking

Jobs track progress through:
- `progress_percent`: 0-100 percentage
- `metadata.chunks_processed`: Number of chunks indexed
- `metadata.total_chunks`: Total chunks to index
- `metadata.retry_count`: Number of retry attempts
- `metadata.last_error`: Last error message (for debugging)

## Error Handling

**Retry Strategy:**
- Transient errors (network, temporary API failures) trigger retry
- Exponential backoff prevents overwhelming services
- Max 3 retries (4 total attempts)
- Each retry logged with attempt number

**Error Storage:**
- `error_message`: Final error if job fails
- `metadata.last_error`: Last error encountered (updated on each retry)
- `metadata.retry_count`: Number of retry attempts made

## API Endpoints

### POST /api/ingest/start
- Creates job with "pending" status
- Schedules background processing
- Returns immediately with job_id

### GET /api/ingest/status/{job_id}
- Returns current job status
- Includes progress percentage
- Shows chunks_processed/total_chunks
- Displays error_message if failed

### GET /api/ingest/list/{user_id}
- Lists all jobs for user
- Ordered by created_at DESC
- Includes all job details

### POST /api/ingest/reindex/{file_id}
- Deletes old embeddings
- Creates new indexing job
- Schedules background processing

## Testing Results

All 6 async job processing tests pass:
```
test_async_job_processing.py::test_create_indexing_job PASSED
test_async_job_processing.py::test_process_indexing_job_success PASSED
test_async_job_processing.py::test_process_indexing_job_retry_on_failure PASSED
test_async_job_processing.py::test_process_indexing_job_max_retries_exceeded PASSED
test_async_job_processing.py::test_job_progress_tracking PASSED
test_async_job_processing.py::test_exponential_backoff_delay PASSED
```

## Benefits

1. **Non-blocking API**: Endpoints return immediately, improving responsiveness
2. **Automatic Retries**: Transient errors handled automatically
3. **Progress Tracking**: Users can monitor indexing progress in real-time
4. **Error Recovery**: Exponential backoff prevents service overload
5. **Detailed Logging**: All retry attempts and errors logged for debugging
6. **User Isolation**: RLS policies ensure users only see their own jobs

## Usage Example

```python
# Client makes request
response = await client.post("/api/ingest/start", json={
    "user_id": "user-123",
    "file_id": "file-456",
    "file_name": "document.pdf"
})
# Returns immediately with: {"job_id": "...", "status": "pending"}

# Poll for status
status = await client.get(f"/api/ingest/status/{job_id}")
# Returns: {
#   "job_id": "...",
#   "status": "processing",
#   "chunks_processed": 50,
#   "total_chunks": 100,
#   "progress_percentage": 50.0
# }
```

## Requirements Satisfied

✅ Create background task queue for indexing jobs  
✅ Track job status in ingestion_jobs table (pending, processing, completed, failed)  
✅ Update progress (chunks_processed, total_chunks, progress_percentage)  
✅ Handle indexing errors and retries with exponential backoff  
✅ Store error messages for failed jobs  
✅ Requirement 13.8 satisfied

## Next Steps

Task 12.4 is complete. The async job processing system is fully functional with:
- Background task processing
- Progress tracking
- Retry logic with exponential backoff
- Comprehensive error handling
- Full test coverage

Ready to proceed with Phase 11 (AI Chat with RAG) or other tasks.
