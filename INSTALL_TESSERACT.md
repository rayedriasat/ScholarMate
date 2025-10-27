# Installing Tesseract OCR on Windows

## Status: ❌ Tesseract NOT Installed

Tesseract OCR is required for the document scanning feature to work. Here's how to install it:

## Quick Installation (Recommended)

### Option 1: Using Chocolatey (Easiest)
If you have Chocolatey package manager installed:

```powershell
choco install tesseract
```

### Option 2: Manual Download (Most Common)

1. **Download the installer:**
   - Visit: https://github.com/UB-Mannheim/tesseract/wiki
   - Download the latest Windows installer (e.g., `tesseract-ocr-w64-setup-5.3.3.20231005.exe`)
   - Or direct link: https://digi.bib.uni-mannheim.de/tesseract/

2. **Run the installer:**
   - Double-click the downloaded `.exe` file
   - **Important:** During installation, note the installation path
   - Default path is usually: `C:\Program Files\Tesseract-OCR`
   - Make sure to check "Add to PATH" if the option is available

3. **Verify installation:**
   ```powershell
   tesseract --version
   ```

4. **If PATH not set automatically:**
   - Open System Properties → Environment Variables
   - Add `C:\Program Files\Tesseract-OCR` to your PATH
   - Restart your terminal/IDE

### Option 3: Using Scoop
If you have Scoop package manager:

```powershell
scoop install tesseract
```

## After Installation

### 1. Verify Tesseract is Working
```powershell
tesseract --version
```

You should see output like:
```
tesseract 5.3.3
 leptonica-1.83.1
  libgif 5.2.1 : libjpeg 8d (libjpeg-turbo 2.1.5.1) : libpng 1.6.40 : libtiff 4.5.1 : zlib 1.2.13 : libwebp 1.3.2 : libopenjp2 2.5.0
```

### 2. Test OCR Backend
```bash
cd backend
uv run python test_ocr.py
```

### 3. Start Backend Server
```bash
cd backend
uv run python run.py
```

### 4. Check OCR Health Endpoint
Open browser or use curl:
```
http://localhost:8000/api/ocr/health
```

Should return:
```json
{
  "status": "healthy",
  "tesseract_version": "5.3.3",
  "available": true
}
```

## Language Data (Optional)

Tesseract supports multiple languages. The installer includes English by default.

To add more languages:
1. Download language data from: https://github.com/tesseract-ocr/tessdata
2. Place `.traineddata` files in: `C:\Program Files\Tesseract-OCR\tessdata\`

Common languages:
- `eng.traineddata` - English (included)
- `fra.traineddata` - French
- `deu.traineddata` - German
- `spa.traineddata` - Spanish
- `chi_sim.traineddata` - Chinese Simplified

## Troubleshooting

### "tesseract not found" error
- Verify installation path exists
- Add to PATH environment variable
- Restart terminal/IDE after PATH change

### Backend can't find Tesseract
The OCR service automatically checks these paths:
- `C:\Program Files\Tesseract-OCR\tesseract.exe`
- `C:\Program Files (x86)\Tesseract-OCR\tesseract.exe`

If installed elsewhere, update `backend/app/services/ocr_service.py`:
```python
pytesseract.pytesseract.tesseract_cmd = r"C:\Your\Custom\Path\tesseract.exe"
```

### Permission errors
- Run installer as Administrator
- Ensure you have write permissions to installation directory

## Alternative: Docker (Advanced)

If you prefer Docker:

```dockerfile
FROM python:3.12
RUN apt-get update && apt-get install -y tesseract-ocr
# ... rest of your Dockerfile
```

## Quick Test

After installation, test with a simple command:

```powershell
# Create a test image with text (or use any image with text)
tesseract test_image.png output
# This creates output.txt with extracted text
```

## Next Steps

Once Tesseract is installed:
1. ✅ Verify with `tesseract --version`
2. ✅ Test backend with `python test_ocr.py`
3. ✅ Start backend server
4. ✅ Test document scanning in the app

## Support

- Tesseract Documentation: https://tesseract-ocr.github.io/
- Windows Installation Guide: https://github.com/UB-Mannheim/tesseract/wiki
- Issue Tracker: https://github.com/tesseract-ocr/tesseract/issues
