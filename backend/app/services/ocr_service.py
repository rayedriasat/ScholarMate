"""OCR service for text extraction from images."""
import base64
import io
import logging
from typing import List, Tuple
from PIL import Image
import pytesseract

logger = logging.getLogger(__name__)


class OCRService:
    """Service for performing OCR on images."""
    
    def __init__(self):
        """Initialize OCR service."""
        # Try to configure tesseract path for Windows
        try:
            # Common Windows installation paths
            import os
            possible_paths = [
                r"C:\Program Files\Tesseract-OCR\tesseract.exe",
                r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe",
            ]
            found = False
            for path in possible_paths:
                if os.path.exists(path):
                    pytesseract.pytesseract.tesseract_cmd = path
                    logger.info(f"✅ Tesseract found and configured at: {path}")
                    found = True
                    break
            
            if not found:
                logger.warning("⚠️ Tesseract not found in common Windows paths. Assuming it's in PATH.")
        except Exception as e:
            logger.warning(f"Could not configure Tesseract path: {e}")
    
    def process_images(self, base64_images: List[str], language: str = "eng") -> List[Tuple[int, str, float]]:
        """
        Process multiple images and extract text using OCR.
        
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
                
                # Get confidence (optional, requires more processing)
                try:
                    data = pytesseract.image_to_data(image, lang=language, output_type=pytesseract.Output.DICT)
                    confidences = [int(conf) for conf in data['conf'] if conf != '-1']
                    avg_confidence = sum(confidences) / len(confidences) if confidences else 0.0
                except Exception as conf_error:
                    logger.warning(f"Could not calculate confidence: {conf_error}")
                    avg_confidence = 0.0
                
                results.append((idx + 1, text.strip(), avg_confidence))
                logger.info(f"Processed page {idx + 1}: {len(text)} characters extracted")
                
            except Exception as e:
                logger.error(f"Error processing image {idx + 1}: {e}")
                results.append((idx + 1, f"[Error processing page: {str(e)}]", 0.0))
        
        return results
    
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
