# Planning Documents Updated - DeepSeek OCR Integration

## Summary

All planning documents have been updated to reflect the new hybrid OCR strategy using DeepSeek OCR for online mode and Flutter Tesseract for offline Android mode, plus the addition of PDF to Markdown conversion and Markdown preview/editor features.

## Files Updated

### 1. `.kiro/specs/scholarmate/tasks.md`
**Changes:**
- Updated Phase 8 (OCR & Document Scanning) with hybrid approach
- Added task 10.2: DeepSeek OCR backend service with PDF-to-Markdown endpoint
- Added task 10.3: Flutter Tesseract for offline Android OCR
- Added task 10.5: Markdown conversion and editor implementation
- Updated test checkpoint to include Markdown features
- Updated future dependencies section with specific packages

**Key Additions:**
```markdown
- DeepSeek OCR service in backend (online mode)
- Flutter Tesseract OCR (offline Android mode)
- PDF to Markdown conversion
- Markdown preview and editor
- OCR mode indicator in UI
```

### 2. `.kiro/specs/scholarmate/requirements.md`
**Changes:**
- Updated Requirement 11 title to "OCR Processing with Hybrid Online/Offline Mode"
- Expanded acceptance criteria to include:
  - DeepSeek OCR for online processing
  - Flutter Tesseract for offline Android processing
  - PDF to Markdown conversion
  - Markdown preview and editor

**Key Additions:**
```markdown
3. WHEN a user completes scanning online, THE Flutter_Client SHALL send images to FastAPI_Backend for DeepSeek OCR processing
4. THE FastAPI_Backend SHALL process images using DeepSeek OCR API to extract text with high accuracy and structure preservation
5. WHEN a user completes scanning offline on Android, THE Flutter_Client SHALL use flutter_tesseract_ocr for local OCR processing
7. THE FastAPI_Backend SHALL provide PDF to Markdown conversion using DeepSeek OCR
8. THE Flutter_Client SHALL provide Markdown preview and editor with live rendering and formatting toolbar
```

### 3. `.kiro/specs/scholarmate/design.md`
**Changes:**
- Updated Phase 8 description in incremental development phases
- Updated OCR Service component to use DeepSeek OCR
- Added new API endpoint: `POST /api/ocr/pdf-to-markdown`
- Added two new Flutter service components:
  - OCRService (client-side)
  - MarkdownService

**Key Additions:**
```python
# Backend OCR Service
class OCRService:
    async def process_image_deepseek(self, image_bytes: bytes) -> Dict[str, Any]:
        """Extract text from image using DeepSeek OCR API with structure preservation"""
    
    async def pdf_to_markdown(self, pdf_bytes: bytes) -> str:
        """Convert PDF to Markdown using DeepSeek OCR"""
```

```dart
# Flutter OCR Service
class OCRService {
  Future<String> processImageOnline(Uint8List imageBytes);
  Future<String> processImageOffline(Uint8List imageBytes);
  Future<String> processImage(Uint8List imageBytes);
}

# Flutter Markdown Service
class MarkdownService {
  Future<String> convertPdfToMarkdown(String fileId);
  Future<void> saveMarkdown(String content, String fileName);
  String renderMarkdown(String content);
}
```

### 4. `.kiro/steering/tech.md`
**Changes:**
- Updated Frontend Core Technologies section
- Updated Backend Core Technologies section

**Key Changes:**
```markdown
Frontend:
+ **OCR (Offline)**: flutter_tesseract_ocr (Android offline mode)
+ **Markdown**: flutter_markdown, markdown_editable_textinput (preview + editor)

Backend:
- **OCR**: Tesseract or EasyOCR
+ **OCR**: DeepSeek OCR (online mode, high accuracy with structure preservation)
```

### 5. `.kiro/steering/product.md`
**Changes:**
- Updated Key Features section

**Key Changes:**
```markdown
- Document scanning with OCR (Tesseract/EasyOCR)
+ Document scanning with hybrid OCR (DeepSeek online / Tesseract offline)
+ PDF to Markdown conversion with structure preservation
+ Markdown preview and editor with live rendering
```

## New Documentation Files

### 1. `OCR_STRATEGY_UPDATE.md`
Comprehensive documentation covering:
- Overview of hybrid OCR architecture
- Online mode (DeepSeek OCR) details
- Offline mode (Flutter Tesseract) details
- PDF to Markdown conversion
- Markdown preview and editor
- Implementation plan
- User experience flows
- Technical details with code examples
- Configuration requirements
- Benefits and migration notes
- Future enhancements

### 2. `PLANNING_DOCS_UPDATED.md` (this file)
Summary of all changes made to planning documents

## Key Features Added

### 1. Hybrid OCR Strategy
- **Online**: DeepSeek OCR via backend API (high accuracy, structure preservation)
- **Offline**: Flutter Tesseract on Android (basic OCR, privacy-preserving)
- **Automatic**: Mode selection based on connectivity status

### 2. PDF to Markdown Conversion
- Convert PDFs to editable Markdown format
- Preserve document structure (tables, lists, headers)
- Backend endpoint for conversion
- Context menu option in PDF viewer

### 3. Markdown Support
- Live preview with flutter_markdown
- Rich text editor with formatting toolbar
- Support for headers, lists, links, tables, code blocks
- Save to Google Drive
- Offline editing with sync queue

## Dependencies to Add

### Frontend (Flutter)
```yaml
dependencies:
  camera: ^0.10.5                              # Document scanning
  flutter_tesseract_ocr: ^0.4.0                # Offline OCR
  flutter_markdown: ^0.6.18                    # Markdown preview
  markdown_editable_textinput: ^2.2.0          # Markdown editor
```

### Backend (Python)
```toml
[project.dependencies]
deepseek-ocr = "^1.0.0"  # DeepSeek OCR SDK (check actual package name)
```

## Environment Variables to Add

### Backend `.env`
```env
DEEPSEEK_API_KEY=your_deepseek_api_key
DEEPSEEK_OCR_ENDPOINT=https://api.deepseek.com/v1/ocr
```

## API Endpoints to Implement

### Backend
```python
POST /api/ocr/process
- Input: { image: base64_string }
- Output: { text: string, confidence: float, structure: object }

POST /api/ocr/pdf-to-markdown
- Input: { file_id: string } or { pdf_bytes: base64_string }
- Output: { markdown: string, metadata: object }
```

## User Workflows Updated

### Document Scanning
1. Capture document with camera
2. **Auto-detect online/offline status**
3. **If online**: Use DeepSeek OCR (high accuracy)
4. **If offline**: Use Tesseract OCR (basic)
5. Show OCR mode indicator
6. Preview OCR text
7. Save as searchable PDF **or convert to Markdown**

### PDF to Markdown
1. Open PDF in viewer
2. Context menu → "Convert to Markdown"
3. **Requires online connection**
4. Backend processes with DeepSeek OCR
5. Opens in Markdown editor
6. Edit and save to Drive

### Markdown Editing
1. Create/open Markdown file
2. Split view (editor + preview)
3. Formatting toolbar
4. Live preview
5. Save to Drive (works offline)

## Testing Requirements

### Phase 8 Test Checkpoint
- ✅ User can scan documents with camera
- ✅ OCR processes images using DeepSeek (online) or Tesseract (offline)
- ✅ Searchable PDFs are created and saved to Drive
- ✅ PDFs can be converted to Markdown
- ✅ Markdown files can be previewed and edited
- ✅ OCR mode indicator shows current mode
- ✅ Offline markdown edits sync when online

## Benefits of This Approach

### Technical
- **Graceful degradation**: Always have OCR capability
- **Best of both worlds**: High accuracy online, privacy offline
- **Model agnostic**: Easy to switch OCR providers
- **Cost effective**: Users can provide their own API keys

### User Experience
- **Always available**: OCR works offline on Android
- **High quality**: DeepSeek provides superior accuracy when online
- **Flexible formats**: PDF or Markdown output
- **Better editing**: Markdown is easier to edit than PDF

### Privacy
- **Offline mode**: Data never leaves device
- **User choice**: Can work entirely offline if preferred
- **Transparent**: UI shows which OCR mode is active

## Next Steps

1. **Phase 7**: Complete annotation synchronization (current priority)
2. **Phase 8**: Implement hybrid OCR system
   - Backend: Integrate DeepSeek OCR API
   - Frontend: Add Flutter Tesseract
   - UI: Add Markdown preview/editor
   - Testing: Verify both modes work correctly

## References

- [DeepSeek OCR GitHub](https://github.com/deepseek-ai/DeepSeek-OCR)
- [flutter_tesseract_ocr](https://pub.dev/packages/flutter_tesseract_ocr)
- [flutter_markdown](https://pub.dev/packages/flutter_markdown)
- [markdown_editable_textinput](https://pub.dev/packages/markdown_editable_textinput)

---

**Status**: ✅ All planning documents updated
**Date**: October 28, 2025
**Impact**: Phase 8 (OCR & Document Scanning) significantly enhanced with hybrid approach and Markdown support
