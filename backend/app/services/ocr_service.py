"""OCR service for text extraction from images using Tesseract OCR."""
import base64
import io
import logging
import os
import platform
from typing import List, Tuple, Dict, Any, Optional
from PIL import Image
import pytesseract

logger = logging.getLogger(__name__)


class OCRService:
    """Service for performing OCR on images using Tesseract OCR."""
    
    def __init__(self):
        """Initialize OCR service with Tesseract."""
        self._configure_tesseract()
        self._verify_tesseract()
    
    def _configure_tesseract(self):
        """Configure Tesseract executable path based on platform."""
        try:
            system = platform.system()
            
            if system == "Windows":
                # Common Windows installation paths
                possible_paths = [
                    r"C:\Program Files\Tesseract-OCR\tesseract.exe",
                    r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
                ]
                for path in possible_paths:
                    if os.path.exists(path):
                        pytesseract.pytesseract.tesseract_cmd = path
                        logger.info(f"✅ Tesseract configured at: {path}")
                        return
                logger.info("⚠️ Tesseract not found in common Windows paths. Assuming it's in PATH.")
            
            elif system == "Linux":
                # On Linux (including Docker), tesseract is usually in PATH
                logger.info("✅ Tesseract configured for Linux (using PATH)")
            
            elif system == "Darwin":
                # macOS - usually installed via Homebrew
                possible_paths = [
                    "/usr/local/bin/tesseract",
                    "/opt/homebrew/bin/tesseract",
                ]
                for path in possible_paths:
                    if os.path.exists(path):
                        pytesseract.pytesseract.tesseract_cmd = path
                        logger.info(f"✅ Tesseract configured at: {path}")
                        return
                logger.info("⚠️ Tesseract not found in common macOS paths. Assuming it's in PATH.")
        
        except Exception as e:
            logger.warning(f"Could not configure Tesseract path: {e}")
    
    def _verify_tesseract(self):
        """Verify Tesseract is available and working."""
        try:
            version = pytesseract.get_tesseract_version()
            logger.info(f"✅ Tesseract OCR v{version} is ready")
        except Exception as e:
            logger.error(f"❌ Tesseract OCR is not available: {e}")
            logger.error("Please install Tesseract OCR to use document scanning features.")
    
    def process_images_tesseract(self, base64_images: List[str], language: str = "eng") -> List[Tuple[int, str, float]]:
        """
        Process images using Tesseract OCR.
        
        Args:
            base64_images: List of base64 encoded images
            language: OCR language code (default: 'eng')
            
        Returns:
            List of tuples (page_number, text, confidence)
        """
        results = []
        
        for idx, base64_image in enumerate(base64_images):
            try:
                # Decode base64 image
                image_data = base64.b64decode(base64_image)
                image = Image.open(io.BytesIO(image_data))
                
                # Perform OCR
                text = pytesseract.image_to_string(image, lang=language)
                
                # Get confidence
                try:
                    data = pytesseract.image_to_data(image, lang=language, output_type=pytesseract.Output.DICT)
                    confidences = [int(conf) for conf in data['conf'] if conf != '-1']
                    avg_confidence = sum(confidences) / len(confidences) if confidences else 0.0
                except Exception as conf_error:
                    logger.warning(f"Could not calculate confidence: {conf_error}")
                    avg_confidence = 0.0
                
                results.append((idx + 1, text.strip(), avg_confidence))
                logger.info(f"Tesseract processed page {idx + 1}: {len(text)} characters, {avg_confidence:.1f}% confidence")
                
            except Exception as e:
                logger.error(f"Error processing image {idx + 1} with Tesseract: {e}")
                results.append((idx + 1, f"[Error: {str(e)}]", 0.0))
        
        return results
    
    async def process_images(self, base64_images: List[str], language: str = "eng") -> List[Tuple[int, str, float]]:
        """
        Process images using Tesseract OCR.
        
        Args:
            base64_images: List of base64 encoded images
            language: OCR language code (default: 'eng')
            
        Returns:
            List of tuples (page_number, text, confidence)
        """
        logger.info(f"Processing {len(base64_images)} images with Tesseract OCR")
        return self.process_images_tesseract(base64_images, language)
    
    async def pdf_to_markdown(self, pdf_bytes: bytes, language: str = "eng") -> str:
        """
        Convert PDF to Markdown using Tesseract OCR.
        
        Args:
            pdf_bytes: PDF file bytes
            language: OCR language code (default: 'eng')
            
        Returns:
            Markdown formatted text
        """
        try:
            from pdf2image import convert_from_bytes
            
            logger.info("Converting PDF to images for OCR processing...")
            
            # Convert PDF pages to images
            images = convert_from_bytes(pdf_bytes)
            logger.info(f"Converted PDF to {len(images)} images")
            
            # Convert images to base64
            base64_images = []
            for img in images:
                buffer = io.BytesIO()
                img.save(buffer, format='PNG')
                img_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
                base64_images.append(img_base64)
            
            # Process with Tesseract
            results = self.process_images_tesseract(base64_images, language)
            
            # Convert to Markdown format
            markdown_parts = []
            for page_num, text, confidence in results:
                if text and not text.startswith('[Error'):
                    markdown_parts.append(f"## Page {page_num}\n\n{text}\n")
            
            markdown = "\n".join(markdown_parts)
            logger.info(f"PDF converted to Markdown: {len(markdown)} characters")
            return markdown
                
        except Exception as e:
            logger.error(f"Error converting PDF to Markdown: {e}")
            raise
    
    def create_searchable_pdf(self, base64_images: List[str], ocr_texts: List[str], output_path: str) -> bool:
        """
        Create a searchable PDF with images and OCR text layer.
        
        Args:
            base64_images: List of base64 encoded images
            ocr_texts: List of OCR extracted texts for each page
            output_path: Path to save the PDF
            
        Returns:
            True if successful, False otherwise
        """
        try:
            from reportlab.pdfgen import canvas
            from reportlab.lib.pagesizes import letter
            from reportlab.lib.utils import ImageReader
            
            c = canvas.Canvas(output_path, pagesize=letter)
            page_width, page_height = letter
            
            for idx, (base64_image, text) in enumerate(zip(base64_images, ocr_texts)):
                try:
                    # Decode and load image
                    image_data = base64.b64decode(base64_image)
                    image = Image.open(io.BytesIO(image_data))
                    
                    # Calculate scaling to fit page
                    img_width, img_height = image.size
                    scale = min(page_width / img_width, page_height / img_height)
                    scaled_width = img_width * scale
                    scaled_height = img_height * scale
                    
                    # Draw image
                    img_reader = ImageReader(io.BytesIO(image_data))
                    c.drawImage(img_reader, 0, page_height - scaled_height, 
                               width=scaled_width, height=scaled_height)
                    
                    # Add invisible text layer for searchability
                    # This is a simplified approach - production would need proper positioning
                    c.setFillColorRGB(1, 1, 1, alpha=0.01)  # Nearly invisible
                    c.setFont("Helvetica", 8)
                    
                    # Split text into lines and add to PDF
                    lines = text.split('\n')
                    y_position = page_height - 20
                    for line in lines[:50]:  # Limit lines to avoid overflow
                        if line.strip():
                            c.drawString(10, y_position, line[:100])  # Limit line length
                            y_position -= 10
                    
                    c.showPage()
                    logger.info(f"Added page {idx + 1} to PDF")
                    
                except Exception as page_error:
                    logger.error(f"Error adding page {idx + 1} to PDF: {page_error}")
                    continue
            
            c.save()
            logger.info(f"Searchable PDF created: {output_path}")
            return True
            
        except Exception as e:
            logger.error(f"Error creating searchable PDF: {e}")
            return False
