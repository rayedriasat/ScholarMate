"""Test OCR with a real image."""
import requests
import base64
import json
from PIL import Image, ImageDraw, ImageFont
from io import BytesIO

BASE_URL = "http://localhost:8000"


def create_test_image():
    """Create a simple test image with text."""
    # Create a white image
    img = Image.new('RGB', (800, 400), color='white')
    draw = ImageDraw.Draw(img)
    
    # Add some text
    text = "Hello World!\nThis is a test document.\nOCR should extract this text."
    
    # Use default font
    try:
        # Try to use a larger font if available
        font = ImageFont.truetype("arial.ttf", 40)
    except:
        # Fall back to default font
        font = ImageFont.load_default()
    
    # Draw text
    draw.text((50, 100), text, fill='black', font=font)
    
    # Convert to base64
    buffered = BytesIO()
    img.save(buffered, format="PNG")
    img_base64 = base64.b64encode(buffered.getvalue()).decode()
    
    return img_base64


def test_ocr_with_image():
    """Test OCR processing with a generated image."""
    print("Creating test image...")
    image_base64 = create_test_image()
    
    print("Sending to OCR service...")
    payload = {
        "images": [image_base64],
        "language": "eng"
    }
    
    response = requests.post(
        f"{BASE_URL}/api/ocr/process",
        json=payload
    )
    
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\n✅ OCR Processing Successful!")
        print(f"Total pages: {data['total_pages']}")
        print(f"\nExtracted text:")
        print("=" * 60)
        for page in data['pages']:
            print(f"\nPage {page['page_number']}:")
            print(f"Confidence: {page['confidence']:.1f}%")
            print(f"Text:\n{page['text']}")
        print("=" * 60)
    else:
        print(f"\n❌ OCR Processing Failed!")
        print(f"Error: {response.text}")


if __name__ == "__main__":
    print("=" * 60)
    print("OCR End-to-End Test")
    print("=" * 60)
    print()
    
    try:
        test_ocr_with_image()
        print("\n" + "=" * 60)
        print("Test completed!")
        print("=" * 60)
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to backend.")
        print("Make sure the backend is running on http://localhost:8000")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
