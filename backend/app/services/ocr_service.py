"""OCR service for text extraction from images using hybrid DeepSeek/Tesseract approach."""
import base64
import io
import logging
import os
from typing import List, Tuple, Dict, Any, Optional
from PIL import Image
import pytesseract
import requests

logger = logging.getLogger(__name__)


class OCRService:
    """Service for performing OCR on images with hybrid DeepSeek/Tesseract support."""
    
    def __init__(self):
        """Initialize OCR service."""
        # Configure Tesseract for offline fallback
        try:
            # Common Windows installation paths
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
        
        # DeepSeek OCR configuration
        self.deepseek_api_key = os.getenv("DEEPSEEK_API_KEY")
        self.deepseek_endpoint = os.getenv("DEEPSEEK_OCR_ENDPOINT", "https://api.deepseek.com/v1/ocr")
        
        if self.deepseek_api_key:
            logger.info("✅ DeepSeek OCR configured (online mode available)")
        else:
            logger.warning("⚠️ DeepSeek API key not found. Only Tesseract (offline) mode available.")
    
    async def process_images_deepseek(self, base64_images: List[str]) -> List[Tuple[int, str, float, Optional[Dict]]]:
        """
        Process images using DeepSeek OCR (online mode with high accuracy).
        
        Args:
            base64_images: List of base64 encoded images
            
        Returns:
            List of tuples (page_number, text, confidence, structure)
        """
        if not self.deepseek_api_key:
            raise ValueError("DeepSeek API key not configured")
        
        results = []
        
        for idx, base64_image in enumerate(base64_images):
            try:
                # Call DeepSeek OCR API
                response = requests.post(
                    self.deepseek_endpoint,
                    headers={
                        "Authorization": f"Bearer {self.deepseek_api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "image": base64_image,
                        "preserve_structure": True,
                        "output_format": "json"
                    },
                    timeout=30
                )
                
                if response.status_code == 200:
                    data = response.json()
                    text = data.get("text", "")
                    confidence = data.get("confidence", 0.0) * 100  # Convert to percentage
                    structure = data.get("structure")
                    
                    results.append((idx + 1, text.strip(), confidence, structure))
                    logger.info(f"DeepSeek processed page {idx + 1}: {len(text)} characters, {confidence:.1f}% confidence")
                else:
                    logger.error(f"DeepSeek API error: {response.status_code} - {response.text}")
                    results.append((idx + 1, f"[DeepSeek API error: {response.status_code}]", 0.0, None))
                    
            except Exception as e:
                logger.error(f"Error calling DeepSeek OCR for image {idx + 1}: {e}")
                results.append((idx + 1, f"[Error: {str(e)}]", 0.0, None))
        
        return results
    
    def process_images_tesseract(self, base64_images: List[str], language: str = "eng") -> List[Tuple[int, str, float]]:
        """
        Process images using Tesseract OCR (offline fallback).
        
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
    
    async def process_images(self, base64_images: List[str], language: str = "eng", use_deepseek: bool = True) -> List[Tuple[int, str, float, Optional[Dict]]]:
        """
        Process images with hybrid OCR (DeepSeek online or Tesseract offline).
        
        Args:
            base64_images: List of base64 encoded images
            language: OCR language code for Tesseract (default: 'eng')
            use_deepseek: Try DeepSeek first if available (default: True)
            
        Returns:
            List of tuples (page_number, text, confidence, structure)
        """
        # Try DeepSeek if requested and available
        if use_deepseek and self.deepseek_api_key:
            try:
                logger.info("Using DeepSeek OCR (online mode)")
                return await self.process_images_deepseek(base64_images)
            except Exception as e:
                logger.warning(f"DeepSeek OCR failed, falling back to Tesseract: {e}")
        
        # Fallback to Tesseract
        logger.info("Using Tesseract OCR (offline mode)")
        tesseract_results = self.process_images_tesseract(base64_images, language)
        # Convert to same format (add None for structure)
        return [(page, text, conf, None) for page, text, conf in tesseract_results]
    
    async def pdf_to_markdown(self, pdf_bytes: bytes) -> str:
        """
        Convert PDF to Markdown using DeepSeek OCR (online only).
        
        Args:
            pdf_bytes: PDF file bytes
            
        Returns:
            Markdown formatted text
        """
        if not self.deepseek_api_key:
            raise ValueError("DeepSeek API key required for PDF to Markdown conversion")
        
        try:
            # Convert PDF bytes to base64
            pdf_base64 = base64.b64encode(pdf_bytes).decode('utf-8')
            
            # Call DeepSeek PDF to Markdown API
            response = requests.post(
                f"{self.deepseek_endpoint}/pdf-to-markdown",
                headers={
                    "Authorization": f"Bearer {self.deepseek_api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "pdf": pdf_base64,
                    "preserve_layout": True,
                    "include_tables": True
                },
                timeout=60
            )
            
            if response.status_code == 200:
                data = response.json()
                markdown = data.get("markdown", "")
                logger.info(f"PDF converted to Markdown: {len(markdown)} characters")
                return markdown
            else:
                error_msg = f"DeepSeek API error: {response.status_code} - {response.text}"
                logger.error(error_msg)
                raise Exception(error_msg)
                
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
