# OCR Document Scanning - Quick Usage Guide

## For Users

### Scanning a Document

1. **Open ScholarMate** and navigate to the folder where you want to save the scanned document

2. **Tap the FAB (+) button** in the bottom right corner

3. **Select "Scan document"** (camera icon) from the menu

4. **Capture pages:**
   - Point camera at document
   - Tap the camera button to capture
   - Repeat for multiple pages
   - Use gallery icon to pick existing images
   - Use undo icon to remove last capture

5. **Review captures:**
   - Swipe through captured pages
   - Tap X on any page to remove it

6. **Process OCR:**
   - Tap "Done" button in top right
   - Wait for OCR processing (shows progress)

7. **Review extracted text:**
   - Check the OCR results for each page
   - View confidence scores
   - Tap "Save" to continue or "Cancel" to retry

8. **Upload:**
   - Document uploads to Google Drive
   - Saved as searchable PDF
   - Automatically appears in file list

### Tips for Best Results

- **Good Lighting**: Ensure document is well-lit
- **Flat Surface**: Place document on flat surface
- **Steady Camera**: Hold camera steady when capturing
- **Clear Text**: Ensure text is in focus and readable
- **High Contrast**: Black text on white background works best

### Troubleshooting

**Camera won't open:**
- Check camera permissions in device settings
- Try using gallery picker instead

**OCR not working:**
- Ensure backend is running
- Check internet connection
- Verify Tesseract is installed on backend server

**Poor OCR results:**
- Retake photo with better lighting
- Ensure text is in focus
- Try flattening document if wrinkled

## For Developers

### Backend Setup

1. **Install Tesseract:**
   ```bash
   # Windows: Download installer
   # macOS: brew install tesseract
   # Linux: sudo apt-get install tesseract-ocr
   ```

2. **Install Python dependencies:**
   ```bash
   cd backend
   uv add pillow pytesseract pdf2image reportlab
   ```

3. **Start backend:**
   ```bash
   uv run python run.py
   ```

4. **Test OCR endpoint:**
   ```bash
   uv run python test_ocr.py
   ```

### Frontend Setup

1. **Install Flutter dependencies:**
   ```bash
   cd frontend
   flutter pub add camera image_picker image path_provider
   ```

2. **Configure permissions:**
   - Android: Add camera permission to AndroidManifest.xml
   - iOS: Add camera usage description to Info.plist

3. **Run app:**
   ```bash
   flutter run
   ```

### API Integration

```dart
// Get OCR service from provider
final ocrService = context.read<OCRService>();

// Process images
final result = await ocrService.processImages(
  imageFiles,
  language: 'eng', // Optional: default is English
);

// Check results
if (result.success) {
  for (final page in result.pages) {
    print('Page ${page.pageNumber}: ${page.text}');
    print('Confidence: ${page.confidence}%');
  }
}

// Check OCR service health
final isAvailable = await ocrService.checkHealth();
```

### Customization

**Change OCR Language:**
```dart
// In document_scanner_screen.dart
final ocrResult = await ocrService.processImages(
  _capturedImages,
  language: 'fra', // French
  // Other options: 'deu' (German), 'spa' (Spanish), etc.
);
```

**Adjust Camera Resolution:**
```dart
// In document_scanner_screen.dart, _initializeCamera()
_cameraController = CameraController(
  cameras.first,
  ResolutionPreset.max, // Change from 'high' to 'max'
  enableAudio: false,
);
```

**Customize PDF Generation:**
Edit `backend/app/services/ocr_service.py` → `create_searchable_pdf()` method

### Testing

**Unit Test OCR Service:**
```python
# backend/test_ocr.py
python test_ocr.py
```

**Integration Test:**
1. Start backend
2. Use Postman/curl to test `/api/ocr/process`
3. Send base64 encoded image
4. Verify response contains extracted text

**End-to-End Test:**
1. Run full app
2. Navigate to file explorer
3. Scan test document
4. Verify upload to Drive
5. Check cache update

## Architecture

```
User → Camera → Capture Images
         ↓
    Base64 Encode
         ↓
    OCR Service (Frontend)
         ↓
    POST /api/ocr/process
         ↓
    OCR Service (Backend)
         ↓
    Tesseract OCR
         ↓
    Extract Text + Confidence
         ↓
    Return to Frontend
         ↓
    Show Preview
         ↓
    Create PDF (Basic)
         ↓
    Upload to Drive
         ↓
    Cache Metadata
```

## Performance Considerations

- **Image Size**: Large images take longer to process
- **Page Count**: More pages = longer processing time
- **Network**: Upload speed depends on connection
- **Backend**: OCR is CPU-intensive, consider scaling

## Security

- Camera permissions required
- Images sent to backend as base64
- No images stored on backend
- PDFs uploaded directly to user's Drive
- User owns all data

## Support

For issues or questions:
1. Check backend logs for OCR errors
2. Verify Tesseract installation
3. Test with `/api/ocr/health` endpoint
4. Review camera permissions
5. Check network connectivity
