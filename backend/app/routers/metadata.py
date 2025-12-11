"""API endpoints for PDF metadata extraction and citation generation."""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional

from app.models.metadata import (
    PDFMetadata,
    Citation,
    CitationRequest,
    MetadataExtractionRequest
)
from app.services.metadata_service import MetadataService, CitationService
from app.services.drive_service import get_drive_service

router = APIRouter(prefix="/api/metadata", tags=["metadata"])


@router.get("/health")
async def health_check():
    """Health check endpoint for metadata service."""
    return {"status": "ok", "service": "metadata"}


@router.post("/extract", response_model=PDFMetadata)
async def extract_metadata(
    request: MetadataExtractionRequest,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """Extract metadata from a PDF file."""
    try:
        print(f"Extracting metadata for file: {request.file_name} (ID: {request.file_id})")
        print(f"User ID: {user_id}")
        
        # Get file from Google Drive
        try:
            drive_service = get_drive_service()
            print(f"Drive service initialized successfully")
        except ValueError as e:
            print(f"Drive service initialization failed: {e}")
            raise HTTPException(
                status_code=500, 
                detail="Backend configuration error: Google Drive credentials not set"
            )
        
        print(f"Fetching file bytes from Google Drive...")
        try:
            file_bytes = drive_service.get_file_bytes(request.file_id, request.access_token)
        except ValueError as e:
            error_msg = str(e)
            print(f"Failed to fetch file: {error_msg}")
            
            if "TOKEN_EXPIRED" in error_msg or "401" in error_msg:
                raise HTTPException(
                    status_code=401,
                    detail="Authentication token expired or invalid. Please sign in again."
                )
            elif "not found" in error_msg.lower() or "404" in error_msg:
                raise HTTPException(
                    status_code=404,
                    detail=f"File not found in Google Drive (" + error_msg + ")"
                )
            elif "INSUFFICIENT_SCOPE" in error_msg:
                raise HTTPException(
                    status_code=403,
                    detail="Insufficient permissions to access this file."
                )
            
            raise HTTPException(status_code=500, detail=f"Failed to fetch file: {error_msg}")
        
        if not file_bytes:
            print(f"File not found: {request.file_id}")
            raise HTTPException(status_code=404, detail="File not found")
        
        print(f"Successfully fetched {len(file_bytes)} bytes")
        
        # Extract metadata
        if request.extract_from_content:
            print("Extracting metadata from first page content...")
            metadata = MetadataService.extract_from_first_page(
                file_bytes,
                request.file_name,
                request.file_id
            )
        else:
            print("Extracting metadata from PDF info...")
            metadata = MetadataService.extract_from_pdf_info(
                file_bytes,
                request.file_name,
                request.file_id
            )
        
        print(f"Extracted metadata: title={metadata.title}, authors={metadata.authors}")
        return metadata
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        print(f"Error extracting metadata: {str(e)}")
        print(error_trace)
        
        # Provide more specific error messages
        error_detail = str(e)
        if "GOOGLE_CLIENT_ID" in error_trace or "GOOGLE_CLIENT_SECRET" in error_trace:
            error_detail = "Backend configuration error: Google OAuth credentials not configured"
        elif "encryption" in error_trace.lower():
            error_detail = "Backend configuration error: Encryption service not configured"
        elif "supabase" in error_trace.lower():
            error_detail = "Backend configuration error: Database connection failed"
        
        raise HTTPException(status_code=500, detail=f"Error extracting metadata: {error_detail}")


@router.post("/citation/generate", response_model=Citation)
async def generate_citation(
    request: CitationRequest,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """Generate citations from an identifier (DOI, ISBN, PMID, arXiv, URL)."""
    try:
        metadata: Optional[PDFMetadata] = None
        
        # Fetch metadata based on identifier type
        if request.identifier_type.lower() == "doi":
            metadata = await CitationService.fetch_metadata_from_doi(request.identifier_value)
        elif request.identifier_type.lower() == "arxiv":
            metadata = await CitationService.fetch_metadata_from_arxiv(request.identifier_value)
        elif request.identifier_type.lower() == "isbn":
            metadata = await CitationService.fetch_metadata_from_isbn(request.identifier_value)
        elif request.identifier_type.lower() == "pmid":
            metadata = await CitationService.fetch_metadata_from_pmid(request.identifier_value)
        elif request.identifier_type.lower() == "url":
            # For URLs, try to extract DOI or arXiv ID first
            if "doi.org/" in request.identifier_value:
                doi = request.identifier_value.split("doi.org/")[-1]
                metadata = await CitationService.fetch_metadata_from_doi(doi)
            elif "arxiv.org/" in request.identifier_value:
                arxiv_match = request.identifier_value.split("/")[-1]
                metadata = await CitationService.fetch_metadata_from_arxiv(arxiv_match)
            else:
                # For general URLs, scrape metadata
                metadata = await CitationService.fetch_metadata_from_url(request.identifier_value)
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported identifier type: {request.identifier_type}"
            )
        
        if not metadata:
            raise HTTPException(
                status_code=404,
                detail=f"Could not fetch metadata for {request.identifier_type}: {request.identifier_value}"
            )
        
        # Generate citations
        citation = CitationService.generate_citations(metadata)
        return citation
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating citation: {str(e)}")


@router.post("/citation/from-metadata", response_model=Citation)
async def generate_citation_from_metadata(
    metadata: PDFMetadata,
    user_id: str = Query(..., description="User ID (Google sub claim)")
):
    """Generate citations from provided metadata."""
    try:
        citation = CitationService.generate_citations(metadata)
        return citation
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating citation: {str(e)}")
