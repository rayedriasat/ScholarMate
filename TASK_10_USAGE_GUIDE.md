# Task 10: Hybrid OCR - Quick Usage Guide

## Setup

### Backend Configuration

1. **Optional: Configure DeepSeek OCR** (for high-accuracy online mode)
   
   Edit `backend/.env`:
   ```env
   DEEPSEEK_API_KEY=your_deepseek_api_key
   DEEPSEEK_OCR_ENDPOINT=https://api.deepseek.com/v1/ocr
   ```
   
   **Note:** If you don't configure DeepSeek, the system will use Tesseract-only mode (offline).

2. **Ensure Tesseract is installed** (for offline fallback)
   - Windows: Already installed at `C:\Program Files\Tesseract-OCR\`
   - macOS: `brew install tesseract`
   - Linux: `sudo apt-get install tesseract-ocr`

3. **Start backend:**
   ```bash
   cd backend
   uv run python run.py
   ```

### Frontend Setup

1. **Install dependencies:**
   ```bash
   cd frontend
   flutter pub get
   ```

2. **Verify Tesseract data (for offline OCR):**
   - English language data is already bundled in `assets/tessdata/eng.traineddata`
   - See `TESSERACT_FLUTTER_SETUP.md` for adding more languages

3. **Run app:**
   ```bash
   flutter run
   ```

## Features

### 1. Hybrid OCR Modes

#### Online Mode (DeepSeek)
- **When:** Internet connected + DeepSeek API key configured
- **Accuracy:** 90%+ typical
- **Features:** Structure preservation, table detection
- **Indicator:** Green "Online" badge with cloud icon

#### Offline Mode (Tesseract)
- **When:** No internet OR DeepSeek not configured
- **Accuracy:** 70-80% typical
- **Features:** Basic text extraction
- **Platform:** Android only (for now)
- **Indicator:** Orange "Offline" badge with bolt icon

### 2. Document Scanning

**Steps:**
1. Open File Explorer
2. Tap FAB (+) button
3. Select "Scan document" (camera icon)
4. Capture pages with camera
5. Tap "Done" when finished
6. Review OCR results
7. Choose save option:
   - **Save as PDF** - Searchable PDF (always available)
   - **Save as Markdown** - Editable Markdown (online only)

### 3. Markdown Editor

**Features:**
- Split view (edit/preview toggle)
- Formatting toolbar:
  - **Bold** (`**text**`)
  - **Italic** (`*text*`)
  - **Strikethrough** (`~~text~~`)
  - **Headers** (`# H1`, `## H2`, `### H3`)
  - **Lists** (`- item`, `1. item`)
  - **Quotes** (`> quote`)
  - **Links** (`[text](url)`)
  - **Code** (`` `code` ``, ` ```block``` `)
- Auto-save to Google Drive
- Unsaved changes warning

## Usage Examples

### Example 1: Scan Document Online
```
1. Ensure internet connection
2. Scan document
3. See "Online" badge (green)
4. Choose "Save as Markdown"
5. Edit in markdown editor
6. Save to Drive
```

### Example 2: Scan Document Offline (Android)
```
1. Disable internet
2. Scan document
3. See "Offline" badge (orange)
4. Choose "Save as PDF" (only option)
5. PDF saved to Drive when online
```

### Example 3: Convert Existing PDF to Markdown
```
(Future feature - not yet implemented)
1. Open PDF in viewer
2. Tap context menu
3. Select "Convert to Markdown"
4. Edit in markdown editor
```

## API Endpoints

### Check OCR Health
```bash
curl http://localhost:8000/api/ocr/health
```

**Response:**
```json
{
  "status": "healthy",
  "tesseract_available": true,
  "deepseek_available": true,
  "ocr_mode": "hybrid"
}
```

### Process Images
```bash
curl -X POST http://localhost:8000/api/ocr/process \
  -H "Content-Type: application/json" \
  -d '{
    "images": ["base64_encoded_image"],
    "language": "eng"
  }'
```

### Convert PDF to Markdown
```bash
curl -X POST http://localhost:8000/api/ocr/pdf-to-markdown \
  -H "Content-Type: application/octet-stream" \
  --data-binary @document.pdf
```

## Troubleshooting

### Issue: "Offline OCR not available"
**Solution:** Offline OCR currently only works on Android. Use online mode on other platforms.

### Issue: "DeepSeek API error"
**Solution:** 
1. Check `DEEPSEEK_API_KEY` in `backend/.env`
2. Verify API key is valid
3. Check internet connection
4. System will fallback to Tesseract automatically

### Issue: "Tesseract not found"
**Solution:**
1. Install Tesseract (see Setup section)
2. Restart backend
3. Check health endpoint

### Issue: "Markdown save option not available"
**Solution:** Markdown conversion requires online mode (DeepSeek). Ensure:
1. Internet connection active
2. DeepSeek API key configured
3. "Online" badge visible in OCR preview

### Issue: Poor OCR accuracy
**Solution:**
1. Use online mode for better accuracy
2. Ensure good lighting when capturing
3. Keep camera steady
4. Use high-contrast documents (black text on white)
5. Avoid blurry or tilted images

## Tips for Best Results

### Camera Capture
- Use good lighting
- Hold camera steady
- Capture straight-on (not at angle)
- Fill frame with document
- Avoid shadows and glare

### Document Quality
- High contrast (black text on white)
- Clear, printed text (not handwritten)
- Flat surface (no curves or wrinkles)
- Standard fonts (avoid decorative fonts)
- Clean pages (no stains or marks)

### OCR Mode Selection
- **Use Online Mode when:**
  - Need high accuracy
  - Processing complex layouts
  - Want Markdown conversion
  - Have stable internet

- **Use Offline Mode when:**
  - No internet available
  - Privacy concerns (data stays on device)
  - Simple text extraction needed
  - On Android device

## Performance

### Online Mode (DeepSeek)
- Processing time: 2-5 seconds per page
- Accuracy: 90-95% typical
- Network required: Yes
- Cost: API usage (user-provided key)

### Offline Mode (Tesseract)
- Processing time: 1-3 seconds per page
- Accuracy: 70-80% typical
- Network required: No
- Cost: Free

## Next Steps

After successful OCR implementation:
1. Test with various document types
2. Gather user feedback on accuracy
3. Consider adding:
   - Automatic edge detection
   - Image enhancement
   - Language selection UI
   - Batch processing
   - iOS offline support

## Support

For issues or questions:
1. Check backend logs: `backend/logs/`
2. Check frontend console output
3. Verify health endpoint status
4. Review this guide's troubleshooting section

## Summary

Task 10 provides:
✅ Hybrid OCR (online + offline)
✅ Automatic mode selection
✅ Searchable PDF generation
✅ Markdown conversion and editing
✅ User-friendly interface
✅ Graceful fallback handling

**Ready to scan documents!** 📄✨
