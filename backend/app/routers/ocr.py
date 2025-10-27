"""OCR API endpoints."""
import logging
import pytesseract
from fastapi import APIRouter, HTTPException, status
from app.models.ocr import OCRProcessRequest, OCRProcessResponse, OCRPageResult
from app.services.ocr_service import OCRService

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/ocr", tags=["ocr"])

# Initialize OCR service
ocr_service = OCRService()


@router.post("/process", response_model=OCRProcessResponse)
async def process_ocr(request: OCRProcessRequest):
    """
    Process images and extract text using OCR.
    
    Args:
        request: OCR process request with base64 encoded images
        
    Returns:
        OCR results with extracted text for each page
    """
    try:
        if not request.images:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No images provided"
            )
        
        logger.info(f"Processing {len(request.images)} images for OCR")
        
        # Process images
        results = ocr_service.process_images(request.images, request.language)
        
        # Build response
        pages = [
            OCRPageResult(
                page_number=page_num,
                text=text,
                confidence=confidence
            )
            for page_num, text, confidence in results
        ]
        
        return OCRProcessResponse(
            success=True,
            pages=pages,
            total_pages=len(pages),
            message=f"Successfully processed {len(pages)} pages"
        )
        
    except Exception as e:
        logger.error(f"OCR processing error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"OCR processing failed: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Check if OCR service is available."""
    try:
        # Use the configured OCR service to check Tesseract
        import os
        
        # Check if tesseract_cmd is configured
        tesseract_path = pytesseract.pytesseract.tesseract_cmd
        
        # If not configured, try common paths
        if tesseract_path == 'tesseract':
            possible_paths = [
                r"C:\Program Files\Tesseract-OCR\tesseract.exe",
                r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
            ]
            for path in possible_paths:
                if os.path.exists(path):
                    pytesseract.pytesseract.tesseract_cmd = path
                    tesseract_path = path
                    break
        
        version = pytesseract.get_tesseract_version()
        return {
            "status": "healthy",
            "tesseract_version": str(version),
            "tesseract_path": tesseract_path,
            "available": True
        }
    except Exception as e:
        logger.warning(f"Tesseract not available: {e}")
        return {
            "status": "unavailable",
            "error": str(e),
            "available": False
        }
