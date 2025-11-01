"""
Ingestion router for RAG indexing endpoints.
"""

import logging
from fastapi import APIRouter, HTTPException, status, Path

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
async def start_indexing(request: StartIndexingRequest) -> StartIndexingResponse:
    """
    Start indexing a file for RAG.
    
    Args:
        request: StartIndexingRequest with user_id, file_id, and optional file_name
        
    Returns:
        StartIndexingResponse with job_id and status
        
    Raises:
        HTTPException: For validation or indexing errors
    """
    try:
        logger.info(f"Starting indexing for file {request.file_id}, user {request.user_id}")
        
        rag_indexer = get_rag_indexer()
        
        # Start indexing job
        job_id = await rag_indexer.index_file(
            file_id=request.file_id,
            user_id=request.user_id,
            file_name=request.file_name
        )
        
        return StartIndexingResponse(
            job_id=job_id,
            status="processing",
            message=f"Indexing started for file {request.file_id}"
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
            detail="Failed to start indexing job"
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
    request: ReindexRequest = None
) -> ReindexResponse:
    """
    Manually reindex a file (delete old embeddings and create new ones).
    
    Args:
        file_id: File ID to reindex
        request: ReindexRequest with user_id and optional file_name
        
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
        
        # Start reindexing job
        job_id = await rag_indexer.reindex_file(
            file_id=file_id,
            user_id=request.user_id,
            file_name=request.file_name
        )
        
        return ReindexResponse(
            job_id=job_id,
            status="processing",
            message=f"Reindexing started for file {file_id}"
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
