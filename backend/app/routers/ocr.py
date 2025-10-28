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
    Process images and extract text using hybrid OCR (DeepSeek online or Tesseract offline).
    
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
        
        # Process images with hybrid approach
        results = await ocr_service.process_images(
            request.images, 
            request.language,
            use_deepseek=True  # Try DeepSeek first, fallback to Tesseract
        )
        
        # Build response
        pages = [
            OCRPageResult(
                page_number=page_num,
                text=text,
                confidence=confidence
            )
            for page_num, text, confidence, _ in results
        ]
        
        # Determine which OCR mode was used
        ocr_mode = "deepseek" if ocr_service.deepseek_api_key else "tesseract"
        
        return OCRProcessResponse(
            success=True,
            pages=pages,
            total_pages=len(pages),
            message=f"Successfully processed {len(pages)} pages using {ocr_mode.upper()}"
        )
        
    except Exception as e:
        logger.error(f"OCR processing error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"OCR processing failed: {str(e)}"
        )


@router.post("/pdf-to-markdown")
async def pdf_to_markdown(file: bytes = None):
    """
    Convert PDF to Markdown using DeepSeek OCR (online only).
    
    Args:
        file: PDF file bytes
        
    Returns:
        Markdown formatted text
    """
    try:
        if not file:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No PDF file provided"
            )
        
        if not ocr_service.deepseek_api_key:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="PDF to Markdown conversion requires DeepSeek API key (online mode only)"
            )
        
        logger.info(f"Converting PDF to Markdown ({len(file)} bytes)")
        
        # Convert PDF to Markdown
        markdown = await ocr_service.pdf_to_markdown(file)
        
        return {
            "success": True,
            "markdown": markdown,
            "message": "PDF successfully converted to Markdown"
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
        
        # Check DeepSeek availability
        deepseek_available = ocr_service.deepseek_api_key is not None
        
        return {
            "status": "healthy",
            "tesseract_version": str(version),
            "tesseract_path": tesseract_path,
            "tesseract_available": True,
            "deepseek_available": deepseek_available,
            "ocr_mode": "hybrid" if deepseek_available else "tesseract_only"
        }
    except Exception as e:
        logger.warning(f"Tesseract not available: {e}")
        return {
            "status": "unavailable",
            "error": str(e),
            "tesseract_available": False,
            "deepseek_available": ocr_service.deepseek_api_key is not None
        }
