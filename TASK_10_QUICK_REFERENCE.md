# Task 10: Hybrid OCR - Quick Reference Card

## 🚀 Quick Start

### Backend Setup
```bash
cd backend
# Optional: Add to .env for online mode
echo "DEEPSEEK_API_KEY=your_key" >> .env
uv run python run.py
```

### Frontend Setup
```bash
cd frontend
flutter pub get  # Tesseract data already bundled
flutter run
```

## 📱 User Features

### Scan Document
1. File Explorer → FAB (+) → Scan
2. Capture pages → Done
3. Review OCR results
4. Choose: PDF or Markdown

### OCR Modes
- **🟢 Online** (DeepSeek): High accuracy, structure preservation
- **🟠 Offline** (Tesseract): Basic accuracy, works without internet

### Markdown Editor
- Edit/Preview toggle
- Formatting toolbar
- Auto-save to Drive
- Unsaved changes warning

## 🔧 API Endpoints

```bash
# Health check
GET /api/ocr/health

# Process images (hybrid)
POST /api/ocr/process
Body: {"images": ["base64..."], "language": "eng"}

# PDF to Markdown (online only)
POST /api/ocr/pdf-to-markdown
Body: PDF bytes
```

## 📊 Mode Comparison

| Feature | Online (DeepSeek) | Offline (Tesseract) |
|---------|-------------------|---------------------|
| Accuracy | 90-95% | 70-80% |
| Speed | 2-5 sec/page | 1-3 sec/page |
| Internet | Required | Not required |
| Platform | All | Android only |
| Markdown | ✅ Yes | ❌ No |
| Cost | API usage | Free |

## 🎯 Key Files

### Backend
- `app/services/ocr_service.py` - Hybrid OCR logic
- `app/routers/ocr.py` - API endpoints

### Frontend
- `lib/services/ocr_service.dart` - Client OCR service
- `lib/screens/document_scanner_screen.dart` - Scanner UI
- `lib/screens/markdown_editor_screen.dart` - Markdown editor

## ⚙️ Configuration

### Backend (.env)
```env
DEEPSEEK_API_KEY=your_key          # Optional
DEEPSEEK_OCR_ENDPOINT=https://...  # Optional
```

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Offline OCR not available" | Android only, use online mode |
| "DeepSeek API error" | Check API key, falls back to Tesseract |
| "Tesseract not found" | Install Tesseract, restart backend |
| "Markdown option missing" | Requires online mode |
| Poor accuracy | Use online mode, good lighting, clear text |

## 📝 Best Practices

### Camera Capture
- ✅ Good lighting
- ✅ Hold steady
- ✅ Straight-on angle
- ✅ Fill frame
- ❌ Avoid shadows/glare

### Document Quality
- ✅ High contrast (black on white)
- ✅ Clear printed text
- ✅ Flat surface
- ❌ Avoid handwriting
- ❌ Avoid decorative fonts

## 🎨 UI Elements

### Mode Indicator
```dart
// Green badge with cloud icon
🟢 Online

// Orange badge with bolt icon
🟠 Offline
```

### Save Options
```dart
// Always available
[Save as PDF]

// Online only
[Save as Markdown]
```

### Markdown Toolbar
```
[B] [I] [~] | [H1] [H2] [H3] | [•] [1.] [>] | [🔗] [`] [```]
```

## 📦 Dependencies

### Backend
- pytesseract
- pillow
- reportlab
- requests

### Frontend
- flutter_tesseract_ocr: ^0.4.30
- flutter_markdown: ^0.7.7+1
- camera: ^0.11.2+1
- connectivity_plus: ^7.0.0

## ✅ Acceptance Criteria

- [x] Camera capture interface
- [x] Perspective correction (basic)
- [x] DeepSeek OCR (online)
- [x] Tesseract OCR (offline)
- [x] Searchable PDF generation
- [x] PDF to Markdown conversion
- [x] Markdown editor with toolbar
- [x] Mode indicator
- [x] Hybrid auto-selection

## 📚 Documentation

- `TASK_10_HYBRID_OCR_COMPLETE.md` - Full documentation
- `TASK_10_USAGE_GUIDE.md` - User guide
- `TASK_10_IMPLEMENTATION_SUMMARY.md` - Technical summary
- `OCR_STRATEGY_UPDATE.md` - Architecture decisions

## 🎉 Status

**✅ COMPLETE** - Production ready!

---

**Quick Test:**
```bash
# 1. Start backend
cd backend && uv run python run.py

# 2. Start frontend
cd frontend && flutter run

# 3. Scan a document
# 4. Verify mode indicator
# 5. Test both save options
```

**Success!** 🚀
