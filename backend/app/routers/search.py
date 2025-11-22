"""
Search router for advanced multi-dimensional search.
"""

import logging
import time
from fastapi import APIRouter, HTTPException, status

from app.models.search import SearchRequest, SearchResponse, SearchResultItem
from app.services.search_service_v2 import get_simple_search_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/search", tags=["Search"])


@router.post("/", response_model=SearchResponse)
async def advanced_search(request: SearchRequest) -> SearchResponse:
    """
    Perform advanced multi-dimensional search.
    
    Searches across:
    - File names (exact, partial, fuzzy matches)
    - PDF and document content (semantic search)
    
    Results are ranked by relevance with exact matches prioritized.
    
    Args:
        request: SearchRequest with query and parameters
        
    Returns:
        SearchResponse with ranked results
        
    Raises:
        HTTPException: For validation errors or service failures
    """
    try:
        start_time = time.time()
        
        logger.info(
            f"Search request from user {request.user_id}: '{request.query}' "
            f"(max: {request.max_results}, semantic: {request.include_semantic})"
        )
        
        # Validate request
        if not request.query.strip():
            raise ValueError("Search query cannot be empty")
        
        if not request.user_id.strip():
            raise ValueError("User ID is required")
        
        # Get simple search service
        search_service = get_simple_search_service()
        
        # Perform search
        results = await search_service.search(
            query=request.query,
            user_id=request.user_id,
            max_results=request.max_results,
            include_semantic=request.include_semantic
        )
        
        # Convert to Pydantic models
        result_items = [
            SearchResultItem(
                file_id=r.file_id,
                file_name=r.file_name,
                match_type=r.match_type,
                relevance_score=r.relevance_score,
                snippet=r.snippet,
                page_number=r.page_number,
                match_context=r.match_context,
                file_size=r.file_size,
                modified_time=r.modified_time,
                mime_type=r.mime_type
            )
            for r in results
        ]
        
        # Calculate search time
        search_time_ms = int((time.time() - start_time) * 1000)
        
        logger.info(
            f"Search completed for user {request.user_id}: "
            f"{len(result_items)} results in {search_time_ms}ms"
        )
        
        return SearchResponse(
            results=result_items,
            total_count=len(result_items),
            query=request.query,
            search_time_ms=search_time_ms
        )
        
    except ValueError as e:
        logger.error(f"Invalid search request: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Unexpected error in search: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred while searching"
        )
