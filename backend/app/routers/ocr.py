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
    Process images and extract text using Tesseract OCR.
    
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
        
        # Process images with Tesseract
        results = await ocr_service.process_images(
            request.images, 
            request.language
        )
        
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
            message=f"Successfully processed {len(pages)} pages using Tesseract OCR"
        )
        
    except Exception as e:
        logger.error(f"OCR processing error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"OCR processing failed: {str(e)}"
        )


@router.post("/pdf-to-markdown")
async def pdf_to_markdown(file: bytes = None, language: str = "eng"):
    """
    Convert PDF to Markdown using Tesseract OCR.
    
    Args:
        file: PDF file bytes
        language: OCR language code (default: 'eng')
        
    Returns:
        Markdown formatted text
    """
    try:
        if not file:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No PDF file provided"
            )
        
        logger.info(f"Converting PDF to Markdown ({len(file)} bytes)")
        
        # Convert PDF to Markdown using Tesseract
        markdown = await ocr_service.pdf_to_markdown(file, language)
        
        return {
            "success": True,
            "markdown": markdown,
            "message": "PDF successfully converted to Markdown using Tesseract OCR"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"PDF to Markdown conversion error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"PDF to Markdown conversion failed: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Check if Tesseract OCR service is available."""
    try:
        # Check Tesseract availability
        tesseract_path = pytesseract.pytesseract.tesseract_cmd
        version = pytesseract.get_tesseract_version()
        
        return {
            "status": "healthy",
            "tesseract_version": str(version),
            "tesseract_path": tesseract_path,
            "tesseract_available": True,
            "ocr_engine": "tesseract"
        }
    except Exception as e:
        logger.warning(f"Tesseract not available: {e}")
        return {
            "status": "unavailable",
            "error": str(e),
            "tesseract_available": False,
            "message": "Please install Tesseract OCR. See installation guide."
        }
