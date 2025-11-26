"""
Ingestion router for RAG indexing endpoints.
"""

import logging
from fastapi import APIRouter, HTTPException, status, Path, BackgroundTasks

from app.models.ingestion import (
    StartIndexingRequest,
    StartIndexingResponse,
    JobStatus,
    JobListResponse,
    ReindexRequest,
    ReindexResponse
)
from app.services.rag_indexer import get_rag_indexer

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/ingest", tags=["Ingestion"])


@router.post("/start", response_model=StartIndexingResponse)
async def start_indexing(
    request: StartIndexingRequest,
    background_tasks: BackgroundTasks
) -> StartIndexingResponse:
    """
    Start indexing a file for RAG in the background.
    
    This endpoint creates a job record and immediately returns, while the actual
    indexing happens asynchronously in the background with retry logic.
    
    Args:
        request: StartIndexingRequest with user_id, file_id, and optional file_name
        background_tasks: FastAPI BackgroundTasks for async processing
        
    Returns:
        StartIndexingResponse with job_id and status
        
    Raises:
        HTTPException: For validation or job creation errors
    """
    try:
        logger.info(f"Starting indexing for file {request.file_id}, user {request.user_id}")
        
        rag_indexer = get_rag_indexer()
        
        # Create indexing job (returns immediately)
        job_id = await rag_indexer.index_file(
            file_id=request.file_id,
            user_id=request.user_id,
            access_token=request.access_token,
            file_name=request.file_name
        )
        
        # Schedule background processing with retry logic
        background_tasks.add_task(
            rag_indexer.process_indexing_job,
            job_id=job_id,
            retry_count=0
        )
        
        logger.info(f"Indexing job {job_id} scheduled for background processing")
        
        return StartIndexingResponse(
            job_id=job_id,
            status="pending",
            message=f"Indexing job created for file {request.file_id}. Processing will begin shortly."
        )
        
    except ValueError as e:
        logger.error(f"Invalid indexing request: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Failed to start indexing: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create indexing job"
        )


@router.get("/status/{job_id}", response_model=JobStatus)
async def get_job_status(
    job_id: str = Path(..., description="Job ID to query")
) -> JobStatus:
    """
    Get indexing job status with progress.
    
    Args:
        job_id: Job ID to query
        
    Returns:
        JobStatus with current status and progress
        
    Raises:
        HTTPException: If job not found
    """
    try:
        logger.info(f"Getting status for job {job_id}")
        
        rag_indexer = get_rag_indexer()
        job_data = await rag_indexer.get_job_status(job_id)
        
        if not job_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Job {job_id} not found"
            )
        
        return JobStatus(**job_data)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get job status: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve job status"
        )


@router.get("/list/{user_id}", response_model=JobListResponse)
async def list_user_jobs(
    user_id: str = Path(..., description="User UUID")
) -> JobListResponse:
    """
    List all indexing jobs for a user.
    
    Args:
        user_id: User UUID
        
    Returns:
        JobListResponse with list of jobs
        
    Raises:
        HTTPException: For query errors
    """
    try:
        logger.info(f"Listing jobs for user {user_id}")
        
        rag_indexer = get_rag_indexer()
        jobs_data = await rag_indexer.list_user_jobs(user_id)
        
        jobs = [JobStatus(**job) for job in jobs_data]
        
        return JobListResponse(
            jobs=jobs,
            total=len(jobs)
        )
        
    except Exception as e:
        logger.error(f"Failed to list user jobs: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve user jobs"
        )


@router.post("/reindex/{file_id}", response_model=ReindexResponse)
async def reindex_file(
    file_id: str = Path(..., description="File ID to reindex"),
    request: ReindexRequest = None,
    background_tasks: BackgroundTasks = None
) -> ReindexResponse:
    """
    Manually reindex a file (delete old embeddings and create new ones) in the background.
    
    This endpoint creates a reindexing job and immediately returns, while the actual
    reindexing happens asynchronously in the background with retry logic.
    
    Args:
        file_id: File ID to reindex
        request: ReindexRequest with user_id and optional file_name
        background_tasks: FastAPI BackgroundTasks for async processing
        
    Returns:
        ReindexResponse with job_id and status
        
    Raises:
        HTTPException: For validation or reindexing errors
    """
    try:
        if not request:
            raise ValueError("Request body is required")
        
        logger.info(f"Reindexing file {file_id} for user {request.user_id}")
        
        rag_indexer = get_rag_indexer()
        
        # Delete existing embeddings first (synchronous)
        rag_indexer.pinecone_service.delete_documents_by_file(request.user_id, file_id)
        
        # Create new indexing job (returns immediately)
        job_id = await rag_indexer.index_file(
            file_id=file_id,
            user_id=request.user_id,
            access_token=request.access_token,
            file_name=request.file_name
        )
        
        # Schedule background processing with retry logic
        if background_tasks:
            background_tasks.add_task(
                rag_indexer.process_indexing_job,
                job_id=job_id,
                retry_count=0
            )
        
        logger.info(f"Reindexing job {job_id} scheduled for background processing")
        
        return ReindexResponse(
            job_id=job_id,
            status="pending",
            message=f"Reindexing job created for file {file_id}. Processing will begin shortly."
        )
        
    except ValueError as e:
        logger.error(f"Invalid reindex request: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Failed to reindex file: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to start reindexing job"
        )



@router.delete("/clear/{user_id}")
async def clear_user_namespace(
    user_id: str = Path(..., description="User ID to clear namespace for")
) -> dict:
    """
    Clear all embeddings for a user (delete entire namespace).
    
    Use this when you need to re-index all documents from scratch,
    such as after an embedding model or API endpoint change.
    
    Args:
        user_id: User UUID or Google sub ID
        
    Returns:
        Success message with namespace info
        
    Raises:
        HTTPException: For deletion errors
    """
    try:
        logger.info(f"Clearing namespace for user {user_id}")
        
        rag_indexer = get_rag_indexer()
        
        # Delete entire namespace
        success = rag_indexer.pinecone_service.delete_namespace(user_id)
        
        if success:
            namespace = rag_indexer.pinecone_service.get_user_namespace(user_id)
            logger.info(f"Successfully cleared namespace {namespace}")
            return {
                "success": True,
                "message": f"Cleared all embeddings for user {user_id}",
                "namespace": namespace
            }
        else:
            raise ValueError("Failed to clear namespace")
        
    except Exception as e:
        logger.error(f"Failed to clear namespace: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to clear namespace: {str(e)}"
        )
