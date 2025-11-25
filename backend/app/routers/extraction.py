"""Document extraction endpoints"""
from fastapi import APIRouter, HTTPException, status, Query
from typing import List, Optional
from ..models.extracted_document import (
    DocumentExtractionRequest,
    DocumentExtractionResponse,
    ExtractedDocumentCreate,
    ExtractedDocumentUpdate,
    ExtractedDocumentResponse,
    ExtractedDocumentListResponse
)
from ..services.extraction_service import get_extraction_service
from ..utils.logging_config import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/api/extraction", tags=["extraction"])


@router.post("/extract", response_model=DocumentExtractionResponse)
async def extract_document(
    request: DocumentExtractionRequest,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Extract structured data from OCR text using AI
    
    Args:
        request: OCR text to process
        user_id: User ID (query parameter)
        
    Returns:
        Extracted document data
    """
    try:
        extraction_service = get_extraction_service()
        
        result = await extraction_service.extract_document_data(request.ocr_text)
        
        return DocumentExtractionResponse(
            document_type=result["document_type"],
            extracted_fields=result["extracted_fields"],
            summary=result["summary"],
            tags=result["tags"]
        )
        
    except Exception as e:
        logger.error(f"Error extracting document: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to extract document: {str(e)}"
        )


@router.post("/documents", response_model=ExtractedDocumentResponse, status_code=status.HTTP_201_CREATED)
async def create_extracted_document(
    document: ExtractedDocumentCreate,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Save an extracted document
    
    Args:
        document: Document data
        user_id: User ID (query parameter)
        
    Returns:
        Created document
    """
    try:
        extraction_service = get_extraction_service()
        
        created = await extraction_service.create_extracted_document(
            user_id=user_id,
            document_type=document.document_type,
            extracted_data=document.extracted_data,
            summary=document.summary,
            image_url=document.image_url,
            tags=document.tags
        )
        
        return ExtractedDocumentResponse(**created)
        
    except Exception as e:
        logger.error(f"Error creating extracted document: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create document: {str(e)}"
        )


@router.get("/documents", response_model=ExtractedDocumentListResponse)
async def get_extracted_documents(
    user_id: str = Query(..., description="User ID (Google sub claim)"),
    type: Optional[str] = Query(None, description="Filter by document type"),
    tags: Optional[str] = Query(None, description="Filter by tags (comma-separated)"),
    q: Optional[str] = Query(None, description="Search query")
):
    """
    Get all extracted documents for a user
    
    Args:
        user_id: User ID (query parameter)
        type: Optional document type filter
        tags: Optional tags filter (comma-separated)
        q: Optional search query
        
    Returns:
        List of extracted documents
    """
    try:
        extraction_service = get_extraction_service()
        
        # Parse tags if provided
        tag_list = tags.split(",") if tags else None
        
        documents = await extraction_service.get_extracted_documents(
            user_id=user_id,
            document_type=type,
            tags=tag_list,
            search_query=q
        )
        
        return ExtractedDocumentListResponse(
            documents=[ExtractedDocumentResponse(**doc) for doc in documents],
            total=len(documents)
        )
        
    except Exception as e:
        logger.error(f"Error getting extracted documents: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get documents: {str(e)}"
        )


@router.get("/documents/{document_id}", response_model=ExtractedDocumentResponse)
async def get_extracted_document(
    document_id: str,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Get a single extracted document by ID
    
    Args:
        document_id: Document ID
        user_id: User ID (query parameter)
        
    Returns:
        Extracted document
    """
    try:
        extraction_service = get_extraction_service()
        
        document = await extraction_service.get_extracted_document(user_id, document_id)
        
        if not document:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Document not found"
            )
        
        return ExtractedDocumentResponse(**document)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting extracted document {document_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get document: {str(e)}"
        )


@router.put("/documents/{document_id}", response_model=ExtractedDocumentResponse)
async def update_extracted_document(
    document_id: str,
    document: ExtractedDocumentUpdate,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Update an extracted document
    
    Args:
        document_id: Document ID
        document: Update data
        user_id: User ID (query parameter)
        
    Returns:
        Updated document
    """
    try:
        extraction_service = get_extraction_service()
        
        # Build update dict with only provided fields
        updates = {}
        if document.document_type is not None:
            updates["document_type"] = document.document_type
        if document.extracted_data is not None:
            updates["extracted_data"] = document.extracted_data
        if document.summary is not None:
            updates["summary"] = document.summary
        if document.image_url is not None:
            updates["image_url"] = document.image_url
        if document.tags is not None:
            updates["tags"] = document.tags
        
        updated = await extraction_service.update_extracted_document(
            user_id=user_id,
            document_id=document_id,
            updates=updates
        )
        
        return ExtractedDocumentResponse(**updated)
        
    except Exception as e:
        logger.error(f"Error updating extracted document {document_id}: {e}")
        if "not found" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=str(e)
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update document: {str(e)}"
        )


@router.delete("/documents/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_extracted_document(
    document_id: str,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """
    Delete an extracted document
    
    Args:
        document_id: Document ID
        user_id: User ID (query parameter)
    """
    try:
        extraction_service = get_extraction_service()
        await extraction_service.delete_extracted_document(user_id, document_id)
        
    except Exception as e:
        logger.error(f"Error deleting extracted document {document_id}: {e}")
        if "not found" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=str(e)
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete document: {str(e)}"
        )
