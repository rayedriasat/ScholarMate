"""
Test async job processing with progress tracking and retry logic.
"""

import pytest
import asyncio
import os
from unittest.mock import Mock, patch, AsyncMock, MagicMock
from app.services.rag_indexer import RAGIndexer, MAX_RETRIES


@pytest.fixture
def mock_env():
    """Mock environment variables."""
    with patch.dict(os.environ, {
        'GOOGLE_CLIENT_ID': 'test_client_id',
        'GOOGLE_CLIENT_SECRET': 'test_client_secret',
        'GROQ_API_KEY': 'test_groq_key',
        'SUPABASE_URL': 'https://test.supabase.co',
        'SUPABASE_SERVICE_KEY': 'test_service_key',
        'ENCRYPTION_KEY': 'test_encryption_key_32_bytes_long!'
    }):
        yield


@pytest.fixture
def mock_rag_indexer(mock_env):
    """Create a RAG indexer with mocked dependencies."""
    with patch('app.services.rag_indexer.get_chroma_service') as mock_chroma, \
         patch('app.services.rag_indexer.get_drive_service') as mock_drive, \
         patch('app.services.rag_indexer.get_supabase_service') as mock_supabase, \
         patch('app.services.rag_indexer.ChatGroq'):
        
        # Setup mock services
        mock_chroma.return_value = MagicMock()
        mock_drive.return_value = MagicMock()
        mock_supabase.return_value = MagicMock()
        
        indexer = RAGIndexer()
        return indexer


@pytest.mark.asyncio
async def test_create_indexing_job(mock_rag_indexer):
    """Test that indexing job is created with pending status."""
    rag_indexer = mock_rag_indexer
    
    with patch.object(rag_indexer, '_create_indexing_job', new_callable=AsyncMock) as mock_create:
        job_id = await rag_indexer.index_file(
            file_id="test_file_123",
            user_id="test_user_456",
            file_name="test.pdf"
        )
        
        # Verify job was created
        assert job_id is not None
        mock_create.assert_called_once()
        call_args = mock_create.call_args
        assert call_args.kwargs['status'] == 'pending'
        assert call_args.kwargs['file_id'] == 'test_file_123'
        assert call_args.kwargs['user_id'] == 'test_user_456'


@pytest.mark.asyncio
async def test_process_indexing_job_success(mock_rag_indexer):
    """Test successful job processing."""
    rag_indexer = mock_rag_indexer
    job_id = "test_job_123"
    
    # Mock job data
    mock_job_data = {
        "job_id": job_id,
        "user_id": "test_user",
        "file_id": "test_file",
        "status": "pending"
    }
    
    async def mock_get_job_status(*args, **kwargs):
        return mock_job_data
    
    async def mock_get_file_bytes(*args, **kwargs):
        return b'fake_pdf_bytes'
    
    async def mock_get_file_metadata(*args, **kwargs):
        return {"name": "test.pdf"}
    
    with patch.object(rag_indexer, 'get_job_status', side_effect=mock_get_job_status), \
         patch.object(rag_indexer, '_update_job_status', new_callable=AsyncMock), \
         patch.object(rag_indexer.drive_service, 'get_file_bytes', side_effect=mock_get_file_bytes), \
         patch.object(rag_indexer.drive_service, 'get_file_metadata', side_effect=mock_get_file_metadata), \
         patch.object(rag_indexer, 'extract_and_chunk_text', return_value=[Mock()]), \
         patch.object(rag_indexer, '_update_job_progress', new_callable=AsyncMock), \
         patch.object(rag_indexer, 'store_embeddings', new_callable=AsyncMock) as mock_store:
        
        await rag_indexer.process_indexing_job(job_id)
        
        # Verify embeddings were stored
        mock_store.assert_called_once()


@pytest.mark.asyncio
async def test_process_indexing_job_retry_on_failure(mock_rag_indexer):
    """Test that job retries with exponential backoff on failure."""
    rag_indexer = mock_rag_indexer
    job_id = "test_job_retry"
    
    mock_job_data = {
        "job_id": job_id,
        "user_id": "test_user",
        "file_id": "test_file",
        "status": "pending"
    }
    
    # Mock to fail first attempt, succeed on second
    call_count = 0
    
    async def mock_get_job_status(*args, **kwargs):
        return mock_job_data
    
    async def mock_get_file_bytes(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        if call_count == 1:
            raise Exception("Network error")
        return b'fake_pdf_bytes'
    
    async def mock_get_file_metadata(*args, **kwargs):
        return {"name": "test.pdf"}
    
    with patch.object(rag_indexer, 'get_job_status', side_effect=mock_get_job_status), \
         patch.object(rag_indexer, '_update_job_status', new_callable=AsyncMock), \
         patch.object(rag_indexer.drive_service, 'get_file_bytes', side_effect=mock_get_file_bytes), \
         patch.object(rag_indexer.drive_service, 'get_file_metadata', side_effect=mock_get_file_metadata), \
         patch.object(rag_indexer, 'extract_and_chunk_text', return_value=[Mock()]), \
         patch.object(rag_indexer, '_update_job_progress', new_callable=AsyncMock), \
         patch.object(rag_indexer, 'store_embeddings', new_callable=AsyncMock), \
         patch.object(rag_indexer, '_update_job_retry_info', new_callable=AsyncMock) as mock_retry, \
         patch('asyncio.sleep', new_callable=AsyncMock):  # Mock sleep to speed up test
        
        await rag_indexer.process_indexing_job(job_id, retry_count=0)
        
        # Verify retry info was updated
        mock_retry.assert_called_once()
        assert call_count == 2  # Failed once, succeeded on retry


@pytest.mark.asyncio
async def test_process_indexing_job_max_retries_exceeded(mock_rag_indexer):
    """Test that job fails after max retries."""
    rag_indexer = mock_rag_indexer
    job_id = "test_job_max_retries"
    
    mock_job_data = {
        "job_id": job_id,
        "user_id": "test_user",
        "file_id": "test_file",
        "status": "pending"
    }
    
    # Mock to always fail
    async def mock_get_job_status(*args, **kwargs):
        return mock_job_data
    
    async def mock_get_file_bytes(*args, **kwargs):
        raise Exception("Persistent error")
    
    with patch.object(rag_indexer, 'get_job_status', side_effect=mock_get_job_status), \
         patch.object(rag_indexer, '_update_job_status', new_callable=AsyncMock) as mock_status, \
         patch.object(rag_indexer.drive_service, 'get_file_bytes', side_effect=mock_get_file_bytes), \
         patch.object(rag_indexer, '_update_job_retry_info', new_callable=AsyncMock), \
         patch('asyncio.sleep', new_callable=AsyncMock):
        
        await rag_indexer.process_indexing_job(job_id, retry_count=MAX_RETRIES)
        
        # Verify job was marked as failed
        # Check if _update_job_status was called with 'failed' status
        failed_calls = [call for call in mock_status.call_args_list 
                       if call.args and len(call.args) >= 2 and call.args[1] == 'failed']
        if not failed_calls:
            # Also check kwargs
            failed_calls = [call for call in mock_status.call_args_list 
                           if call.kwargs.get('status') == 'failed']
        assert len(failed_calls) > 0, f"Expected 'failed' status call, got: {mock_status.call_args_list}"


@pytest.mark.asyncio
async def test_job_progress_tracking(mock_rag_indexer):
    """Test that job progress is tracked correctly."""
    rag_indexer = mock_rag_indexer
    job_id = "test_job_progress"
    
    mock_job_data = {
        "job_id": job_id,
        "user_id": "test_user",
        "file_id": "test_file",
        "status": "pending"
    }
    
    # Create mock documents
    mock_docs = [Mock() for _ in range(10)]
    
    async def mock_get_job_status(*args, **kwargs):
        return mock_job_data
    
    async def mock_get_file_bytes(*args, **kwargs):
        return b'fake_pdf_bytes'
    
    async def mock_get_file_metadata(*args, **kwargs):
        return {"name": "test.pdf"}
    
    with patch.object(rag_indexer, 'get_job_status', side_effect=mock_get_job_status), \
         patch.object(rag_indexer, '_update_job_status', new_callable=AsyncMock), \
         patch.object(rag_indexer.drive_service, 'get_file_bytes', side_effect=mock_get_file_bytes), \
         patch.object(rag_indexer.drive_service, 'get_file_metadata', side_effect=mock_get_file_metadata), \
         patch.object(rag_indexer, 'extract_and_chunk_text', return_value=mock_docs), \
         patch.object(rag_indexer, '_update_job_progress', new_callable=AsyncMock) as mock_progress, \
         patch.object(rag_indexer, 'store_embeddings', new_callable=AsyncMock):
        
        await rag_indexer.process_indexing_job(job_id)
        
        # Verify progress was updated with correct chunk counts
        assert mock_progress.call_count >= 1
        # Check that total_chunks was set correctly
        progress_calls = mock_progress.call_args_list
        assert any(call.kwargs.get('total_chunks') == 10 for call in progress_calls)


@pytest.mark.asyncio
async def test_exponential_backoff_delay(mock_rag_indexer):
    """Test that retry delays follow exponential backoff."""
    rag_indexer = mock_rag_indexer
    job_id = "test_job_backoff"
    
    mock_job_data = {
        "job_id": job_id,
        "user_id": "test_user",
        "file_id": "test_file",
        "status": "pending"
    }
    
    sleep_delays = []
    
    async def mock_sleep(delay):
        sleep_delays.append(delay)
    
    async def mock_get_job_status(*args, **kwargs):
        return mock_job_data
    
    # Mock to fail multiple times
    call_count = 0
    
    async def mock_get_file_bytes(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        if call_count <= 2:
            raise Exception("Temporary error")
        return b'fake_pdf_bytes'
    
    async def mock_get_file_metadata(*args, **kwargs):
        return {"name": "test.pdf"}
    
    with patch.object(rag_indexer, 'get_job_status', side_effect=mock_get_job_status), \
         patch.object(rag_indexer, '_update_job_status', new_callable=AsyncMock), \
         patch.object(rag_indexer.drive_service, 'get_file_bytes', side_effect=mock_get_file_bytes), \
         patch.object(rag_indexer.drive_service, 'get_file_metadata', side_effect=mock_get_file_metadata), \
         patch.object(rag_indexer, 'extract_and_chunk_text', return_value=[Mock()]), \
         patch.object(rag_indexer, '_update_job_progress', new_callable=AsyncMock), \
         patch.object(rag_indexer, 'store_embeddings', new_callable=AsyncMock), \
         patch.object(rag_indexer, '_update_job_retry_info', new_callable=AsyncMock), \
         patch('asyncio.sleep', side_effect=mock_sleep):
        
        await rag_indexer.process_indexing_job(job_id, retry_count=0)
        
        # Verify exponential backoff: delays should increase
        assert len(sleep_delays) >= 1
        if len(sleep_delays) > 1:
            assert sleep_delays[1] > sleep_delays[0]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
