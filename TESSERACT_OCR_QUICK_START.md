# Tesseract OCR - Quick Start Guide

## 🚀 What Changed?

ScholarMate now uses **Tesseract OCR exclusively** for all document scanning. DeepSeek OCR has been removed.

## ✅ Benefits

- **Free** - No API costs or rate limits
- **Private** - All processing local or on your backend
- **Offline** - Works without internet connection
- **Simple** - No API keys to manage

## 📦 Installation

### Backend (Required)

**Windows:**
```bash
# Download installer
https://github.com/UB-Mannheim/tesseract/wiki

# Or use Chocolatey
choco install tesseract
```

**Linux:**
```bash
sudo apt-get update
sudo apt-get install tesseract-ocr tesseract-ocr-eng poppler-utils
```

**macOS:**
```bash
brew install tesseract poppler
```

### Frontend (Mobile Only)

**Android:** ✅ Language data already bundled in `assets/tessdata/`

**iOS/Web/Desktop:** Uses backend API (no local install needed)

## 🧪 Quick Test

### 1. Test Backend
```bash
cd backend
uv run python test_ocr.py
```

**Expected Output:**
```
✅ Tesseract OCR is available and ready!
   Version: 5.x.x
   Path: /path/to/tesseract
```

### 2. Start Backend
```bash
cd backend
uv run python run.py
```

### 3. Test API
```bash
curl http://localhost:8000/api/ocr/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "tesseract_version": "5.x.x",
  "tesseract_path": "/path/to/tesseract",
  "tesseract_available": true,
  "ocr_engine": "tesseract"
}
```

### 4. Test Frontend
```bash
cd frontend
flutter run -d chrome
```

Open document scanner and test OCR with an image.

## 🔧 How It Works

### Architecture
```
Web Platform:
  User → Frontend → Backend API → Tesseract → Results

Mobile/Desktop (Online):
  User → Frontend → Backend API → Tesseract → Results
                ↓ (if backend fails)
         Local Tesseract → Results

Mobile/Desktop (Offline):
  User → Frontend → Local Tesseract → Results
```

### Automatic Fallback
1. **Online**: Tries backend first (better performance)
2. **Backend fails**: Falls back to local Tesseract
3. **Offline**: Uses local Tesseract directly

## 📝 API Endpoints

### Health Check
```bash
GET /api/ocr/health
```

### Process Images
```bash
POST /api/ocr/process
Content-Type: application/json

{
  "images": ["base64_image_1", "base64_image_2"],
  "language": "eng"
}
```

### PDF to Markdown
```bash
POST /api/ocr/pdf-to-markdown?language=eng
Content-Type: application/octet-stream

<PDF binary data>
```

## 🌍 Multi-Language Support

### Install Language Packs

**Windows:**
Download from: https://github.com/tesseract-ocr/tessdata

**Linux:**
```bash
sudo apt-get install tesseract-ocr-fra  # French
sudo apt-get install tesseract-ocr-deu  # German
sudo apt-get install tesseract-ocr-spa  # Spanish
```

**macOS:**
```bash
brew install tesseract-lang
```

### Use in API
```json
{
  "images": ["base64_image"],
  "language": "fra"  // French
}
```

## 🐛 Troubleshooting

### "Tesseract not found"

**Solution:** Install Tesseract (see Installation above)

**Verify:**
```bash
tesseract --version
```

### Low OCR Accuracy

**Solutions:**
- Use high-quality, well-lit images
- Ensure text is clear and not blurry
- Use appropriate language pack
- Adjust image contrast/brightness

### PDF to Markdown Fails

**Solution:** Install poppler-utils

**Linux:**
```bash
sudo apt-get install poppler-utils
```

**macOS:**
```bash
brew install poppler
```

**Windows:**
Download from: https://github.com/oschwartz10612/poppler-windows/releases

### Offline Mode Not Working (Mobile)

**Check:**
1. Language data in `assets/tessdata/eng.traineddata`
2. App has storage permissions
3. Check logs for initialization errors

## 📚 Documentation

- **Full Migration Guide**: `OCR_TESSERACT_ONLY.md`
- **Migration Summary**: `OCR_MIGRATION_SUMMARY.md`
- **Testing Checklist**: `OCR_MIGRATION_CHECKLIST.md`

## 🎯 Next Steps

1. ✅ Install Tesseract on your system
2. ✅ Restart backend server
3. ✅ Test OCR functionality
4. ✅ Deploy to production

## 💡 Tips

- **Better Results**: Use high-resolution images (300 DPI+)
- **Speed**: Backend processing is faster than local
- **Offline**: Local Tesseract works great for basic documents
- **Languages**: Install only the language packs you need

---

**Status**: ✅ Ready to use!

**Support**: See troubleshooting section or check logs for errors.
