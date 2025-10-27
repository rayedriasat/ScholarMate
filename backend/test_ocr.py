"""Test script for OCR functionality."""
import requests
import base64
import json
from pathlib import Path

BASE_URL = "http://localhost:8000"


def test_ocr_health():
    """Test OCR health endpoint."""
    print("Testing OCR health endpoint...")
    response = requests.get(f"{BASE_URL}/api/ocr/health")
    print(f"Status: {response.status_code}")
    data = response.json()
    print(f"Response: {json.dumps(data, indent=2)}")
    
    if not data.get('available', False):
        print("\n⚠️  WARNING: Tesseract OCR is not available!")
        print("Please install Tesseract OCR to use document scanning.")
        print("See INSTALL_TESSERACT.md for installation instructions.")
        print("\nQuick install (Windows):")
        print("  1. Download from: https://github.com/UB-Mannheim/tesseract/wiki")
        print("  2. Run installer")
        print("  3. Restart backend server")
    else:
        print("\n✅ Tesseract OCR is available and ready!")
    print()


def test_ocr_process():
    """Test OCR processing with a sample image."""
    print("Testing OCR process endpoint...")
    
    # Create a simple test image (you can replace this with an actual image file)
    # For this test, we'll use a placeholder
    # In real testing, you would load an actual image file
    
    # Example: Load an image file
    # image_path = Path("test_image.png")
    # if image_path.exists():
    #     with open(image_path, "rb") as f:
    #         image_data = base64.b64encode(f.read()).decode()
    #     
    #     payload = {
    #         "images": [image_data],
    #         "language": "eng"
    #     }
    #     
    #     response = requests.post(
    #         f"{BASE_URL}/api/ocr/process",
    #         json=payload
    #     )
    #     print(f"Status: {response.status_code}")
    #     print(f"Response: {json.dumps(response.json(), indent=2)}")
    # else:
    #     print("No test image found. Please create test_image.png")
    
    print("Note: To test OCR processing, create a test_image.png file")
    print("and uncomment the code above.")
    print()


if __name__ == "__main__":
    print("=" * 60)
    print("OCR Service Test")
    print("=" * 60)
    print()
    
    try:
        test_ocr_health()
        test_ocr_process()
        
        print("=" * 60)
        print("Tests completed!")
        print("=" * 60)
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to backend.")
        print("Make sure the backend is running on http://localhost:8000")
    except Exception as e:
        print(f"Error: {e}")
