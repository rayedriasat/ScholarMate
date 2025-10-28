# OCR Strategy Update - DeepSeek OCR Integration

## Overview

ScholarMate's OCR strategy has been updated to use a hybrid approach that provides high-accuracy OCR when online and basic OCR capabilities when offline on Android devices.

## New OCR Architecture

### Online Mode: DeepSeek OCR (Backend)
- **Provider**: [DeepSeek OCR](https://github.com/deepseek-ai/DeepSeek-OCR)
- **Location**: FastAPI backend service
- **Advantages**:
  - High accuracy text extraction
  - Structure preservation (tables, lists, formatting)
  - PDF to Markdown conversion with layout understanding
  - Advanced document understanding
  - No client-side resource consumption

### Offline Mode: Flutter Tesseract (Android)
- **Provider**: flutter_tesseract_ocr package
- **Location**: Flutter Android app
- **Advantages**:
  - Works completely offline
  - No internet required
  - Basic text extraction
  - Lightweight and fast
  - Privacy-preserving (no data leaves device)

## Key Features

### 1. Hybrid OCR Processing
```dart
// Automatic mode selection based on connectivity
Future<String> processImage(Uint8List imageBytes) async {
  if (await connectivityService.isOnline()) {
    return await processImageOnline(imageBytes); // DeepSeek OCR
  } else {
    return await processImageOffline(imageBytes); // Tesseract
  }
}
```

### 2. PDF to Markdown Conversion
- **Online only** (requires DeepSeek OCR)
- Preserves document structure
- Converts tables, lists, headers, and formatting
- Accessible via context menu in PDF viewer
- Backend endpoint: `POST /api/ocr/pdf-to-markdown`

### 3. Markdown Preview and Editor
- Live markdown rendering with flutter_markdown
- Rich text editor with formatting toolbar
- Support for:
  - Headers (H1-H6)
  - Bold, italic, strikethrough
  - Lists (ordered, unordered)
  - Links and images
  - Code blocks
  - Tables
- Save to Google Drive
- Offline editing with sync queue

## Implementation Plan (Phase 8)

### Backend Tasks
1. **DeepSeek OCR Integration**
   - Add DeepSeek OCR SDK to pyproject.toml
   - Implement `POST /api/ocr/process` endpoint
   - Implement `POST /api/ocr/pdf-to-markdown` endpoint
   - Handle API authentication and rate limiting
   - Error handling and fallback strategies

2. **API Endpoints**
   ```python
   POST /api/ocr/process
   - Input: image bytes (base64)
   - Output: { text: string, confidence: float, structure: object }
   
   POST /api/ocr/pdf-to-markdown
   - Input: PDF file ID or bytes
   - Output: { markdown: string, metadata: object }
   ```

### Frontend Tasks
1. **Flutter Tesseract Integration**
   - Add flutter_tesseract_ocr dependency
   - Download and cache Tesseract language data
   - Implement offline OCR processing
   - Show OCR mode indicator in UI

2. **Markdown Support**
   - Add flutter_markdown dependency
   - Add markdown_editable_textinput dependency
   - Create MarkdownPreviewScreen
   - Create MarkdownEditorScreen
   - Implement toolbar with formatting options

3. **UI Enhancements**
   - OCR mode indicator (DeepSeek/Tesseract)
   - "Convert to Markdown" option in PDF context menu
   - Markdown file type support in file explorer
   - Preview/Edit toggle for markdown files

## User Experience

### Document Scanning Flow
1. User taps scan button in file explorer
2. Camera opens with document capture UI
3. User captures one or more pages
4. App detects online/offline status
5. **If online**: Sends to DeepSeek OCR (high accuracy)
6. **If offline**: Uses Tesseract OCR (basic)
7. Shows OCR mode indicator and processing progress
8. Displays OCR text preview
9. User can:
   - Save as searchable PDF
   - Convert to Markdown (online only)
   - Edit text before saving

### PDF to Markdown Conversion
1. User opens PDF in viewer
2. Taps context menu → "Convert to Markdown"
3. **Requires online connection**
4. Backend processes PDF with DeepSeek OCR
5. Returns structured Markdown
6. Opens in Markdown editor
7. User can edit and save to Drive

### Markdown Editing
1. User creates new Markdown file or opens existing
2. Opens in split view (editor + preview)
3. Toolbar provides formatting shortcuts
4. Live preview updates as user types
5. Save to Google Drive
6. Works offline with sync queue

## Technical Details

### DeepSeek OCR API
```python
from deepseek_ocr import DeepSeekOCR

class OCRService:
    def __init__(self):
        self.ocr_client = DeepSeekOCR(api_key=os.getenv("DEEPSEEK_API_KEY"))
    
    async def process_image_deepseek(self, image_bytes: bytes) -> Dict[str, Any]:
        """Extract text with structure preservation"""
        result = await self.ocr_client.recognize(
            image=image_bytes,
            preserve_structure=True,
            output_format="json"
        )
        return {
            "text": result.text,
            "confidence": result.confidence,
            "structure": result.structure,
            "bounding_boxes": result.boxes
        }
    
    async def pdf_to_markdown(self, pdf_bytes: bytes) -> str:
        """Convert PDF to Markdown"""
        result = await self.ocr_client.pdf_to_markdown(
            pdf=pdf_bytes,
            preserve_layout=True
        )
        return result.markdown
```

### Flutter Tesseract Integration
```dart
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class OCRService {
  Future<String> processImageOffline(Uint8List imageBytes) async {
    // Save image temporarily
    final tempFile = await _saveTempImage(imageBytes);
    
    // Run Tesseract OCR
    final text = await FlutterTesseractOcr.extractText(
      tempFile.path,
      language: 'eng',
      args: {
        "psm": "3", // Fully automatic page segmentation
        "preserve_interword_spaces": "1",
      }
    );
    
    // Cleanup
    await tempFile.delete();
    
    return text;
  }
  
  Future<void> downloadTesseractData() async {
    // Download language data on first use
    await FlutterTesseractOcr.downloadLanguageData('eng');
  }
}
```

## Configuration

### Backend Environment Variables
```env
# .env
DEEPSEEK_API_KEY=your_deepseek_api_key
DEEPSEEK_OCR_ENDPOINT=https://api.deepseek.com/v1/ocr
```

### Frontend Dependencies
```yaml
# pubspec.yaml
dependencies:
  flutter_tesseract_ocr: ^0.4.0
  flutter_markdown: ^0.6.18
  markdown_editable_textinput: ^2.2.0
  camera: ^0.10.5
```

## Benefits

### For Users
- **High accuracy** when online (DeepSeek OCR)
- **Always available** OCR even offline (Tesseract)
- **Markdown conversion** for better document editing
- **Structure preservation** in converted documents
- **Flexible workflow** - scan, convert, edit

### For Development
- **Model agnostic** - can switch OCR providers easily
- **Graceful degradation** - offline mode always works
- **Cost effective** - users can provide their own DeepSeek API keys
- **Privacy options** - offline mode keeps data on device

## Migration Notes

### From Previous Tesseract-Only Approach
- No breaking changes to existing code
- Backend OCR service enhanced with DeepSeek
- Frontend gains offline capability
- Existing OCR endpoints remain compatible

### Testing Requirements
1. Test online OCR with various document types
2. Test offline OCR on Android devices
3. Test automatic mode switching
4. Test PDF to Markdown conversion
5. Test Markdown editor functionality
6. Test sync queue for offline markdown edits

## Future Enhancements

### Potential Additions
- iOS offline OCR support (ML Kit or similar)
- Web offline OCR (Tesseract.js)
- OCR language selection
- Batch document processing
- OCR quality comparison (DeepSeek vs Tesseract)
- Custom OCR training for specialized documents

### Advanced Features
- Table extraction and Excel export
- Form field detection and extraction
- Handwriting recognition (if DeepSeek supports)
- Multi-language document support
- OCR result confidence scoring

## References

- [DeepSeek OCR GitHub](https://github.com/deepseek-ai/DeepSeek-OCR)
- [flutter_tesseract_ocr Package](https://pub.dev/packages/flutter_tesseract_ocr)
- [flutter_markdown Package](https://pub.dev/packages/flutter_markdown)
- [markdown_editable_textinput Package](https://pub.dev/packages/markdown_editable_textinput)

## Summary

The hybrid OCR strategy provides the best of both worlds:
- **DeepSeek OCR** for high-accuracy, structure-preserving OCR when online
- **Flutter Tesseract** for basic but reliable OCR when offline on Android
- **Markdown conversion** for better document editing and formatting
- **Seamless switching** based on connectivity status

This approach ensures ScholarMate users always have OCR capabilities regardless of their connection status, while providing premium features when online.
