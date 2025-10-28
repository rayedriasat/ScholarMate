# How to Test Offline OCR - Step by Step

## Quick Answer to Your Question

**To run the test script:**
```bash
cd frontend
flutter run test_tessdata_copy.dart
```

This will launch a simple test app that verifies tessdata copying works correctly.

## What Was Fixed

The error `"Unable to load asset: assets/tessdata_config.json"` was caused by:
1. Missing `tessdata_config.json` file ✅ **FIXED** - Created the file
2. Tessdata path not specified to Tesseract ✅ **FIXED** - Added `tessdata` parameter

## Step-by-Step Testing

### Option 1: Run Test Script (Recommended First)

**1. Navigate to frontend directory:**
```bash
cd frontend
```

**2. Run the test script:**
```bash
flutter run test_tessdata_copy.dart
```

**3. What you'll see:**
- A simple app with a "Run Test" button
- Click the button
- Watch it test each step:
  - ✅ Step 1: Checking asset...
  - ✅ Step 2: Getting app directory...
  - ✅ Step 3: Creating tessdata directory...
  - ✅ Step 4: Copying tessdata file...
  - ✅ Step 5: Verifying file...

**4. Expected result:**
```
✅ TEST PASSED!

Asset size: 22.4 MB
File location: /data/data/.../tessdata/eng.traineddata
File size: 22.4 MB

Tessdata is ready for offline OCR!
```

### Option 2: Test in Main App

**1. Clean and rebuild:**
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

**2. Enable airplane mode on your device**

**3. Test offline OCR:**
- Open the app
- Go to File Explorer
- Tap FAB (+) → Scan document
- Capture a page with text
- Tap "Done"

**4. What to look for:**
- 🟠 **Orange "Offline" badge** (not green)
- Processing message
- OCR preview with extracted text
- **NO error about tessdata_config.json**

**5. Check logs:**
```bash
adb logcat | grep -E "(Tesseract|OCR)"
```

**Expected logs:**
```
I/flutter: Copying tessdata from assets...
I/flutter: Tessdata copied successfully: /data/data/.../tessdata/eng.traineddata
I/flutter: Tesseract initialized with language data at: ...
I/flutter: Processing image 1 with Tesseract (offline)...
I/flutter: Using tessdata path: /data/data/.../files
I/flutter: Extracted 245 characters from page 1
```

## What Changed to Fix the Error

### 1. Created tessdata_config.json
```json
{
  "version": "4.0.0",
  "languages": ["eng"],
  "tessdata_dir": "tessdata"
}
```
Location: `frontend/assets/tessdata/tessdata_config.json`

### 2. Updated OCR Service
Added explicit tessdata path parameter:
```dart
final text = await FlutterTesseractOcr.extractText(
  imageFiles[i].path,
  language: language,
  args: {
    "psm": "3",
    "preserve_interword_spaces": "1",
    "tessdata": tessdataPath, // ✅ Added this
  },
);
```

### 3. Added Better Error Logging
```dart
debugPrint('Using tessdata path: $tessdataPath');
debugPrint('Error details: ${e.toString()}');
```

## Troubleshooting

### Still Getting tessdata_config.json Error?

**1. Verify file exists:**
```bash
ls frontend/assets/tessdata/
# Should show:
# - eng.traineddata (23MB)
# - tessdata_config.json (new)
```

**2. Clean and rebuild:**
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

**3. Check pubspec.yaml:**
```yaml
assets:
  - assets/tessdata/  # Must be present
```

### Getting Different Error?

**Run test script to isolate the issue:**
```bash
flutter run test_tessdata_copy.dart
```

The test script will show exactly which step fails:
- Step 1 fails → Asset not found in bundle
- Step 2 fails → Can't access app directory
- Step 3 fails → Can't create directory
- Step 4 fails → Can't copy file
- Step 5 fails → File size mismatch

### OCR Returns Empty Text?

**Possible causes:**
1. **Poor image quality** - Use good lighting, clear text
2. **Wrong language** - Verify using 'eng' for English
3. **Tessdata corrupted** - Delete and re-copy:
   ```bash
   adb shell run-as com.example.frontend rm -rf files/tessdata
   # Then run app again to re-copy
   ```

## Expected Performance

### First Run
- Tessdata copy: ~5 seconds
- OCR processing: 1-3 seconds
- **Total: ~6-8 seconds**

### Subsequent Runs
- Tessdata already copied: instant
- OCR processing: 1-3 seconds
- **Total: ~1-3 seconds**

## Success Indicators

✅ Test script shows "TEST PASSED"
✅ Orange "Offline" badge appears
✅ Text is extracted (even if not perfect)
✅ No tessdata_config.json error
✅ Logs show "Tesseract initialized"
✅ Can save as PDF

## Quick Commands Reference

```bash
# Run test script
cd frontend && flutter run test_tessdata_copy.dart

# Run main app
cd frontend && flutter run

# Clean rebuild
cd frontend && flutter clean && flutter pub get && flutter run

# View logs
adb logcat | grep -i tesseract

# Check tessdata on device
adb shell run-as com.example.frontend ls -la files/tessdata/

# Clear app data
adb shell pm clear com.example.frontend
```

## What to Expect

### ✅ Working Offline OCR
```
User scans document (airplane mode on)
  ↓
App detects offline mode
  ↓
First time: Copies tessdata (~5s)
  ↓
Processes with Tesseract (~1-3s)
  ↓
Shows orange "Offline" badge
  ↓
Displays extracted text (70-80% accuracy)
  ↓
User saves as PDF
```

### ❌ Previous Error (Now Fixed)
```
User scans document
  ↓
App tries to use Tesseract
  ↓
Error: "Unable to load asset: tessdata_config.json"
  ↓
Shows confidence 0.0%
  ↓
No text extracted
```

## Next Steps

1. **Run test script** to verify tessdata copying works
2. **Test in main app** with airplane mode
3. **Check logs** for any errors
4. **Try different images** to test accuracy
5. **Compare** with online mode (DeepSeek)

## Need Help?

If you're still having issues:

1. **Run test script** and share results
2. **Capture logs:**
   ```bash
   adb logcat > ocr_debug.log
   # Reproduce issue
   # Ctrl+C
   # Share ocr_debug.log
   ```
3. **Check** OFFLINE_OCR_TROUBLESHOOTING.md for detailed debugging

**The offline OCR should now work without the tessdata_config.json error!** 📱✨
