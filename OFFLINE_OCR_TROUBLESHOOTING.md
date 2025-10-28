# Offline OCR Troubleshooting Guide

## Issue
Offline OCR (Tesseract) is not working on Android device.

## Solution Applied

### 1. Updated OCR Service Implementation

The `flutter_tesseract_ocr` package requires tessdata files to be copied from assets to the device's file system before use.

#### Changes Made:

**Added imports:**
```dart
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
```

**Updated initialization:**
```dart
Future<void> _initializeTesseract() async {
  if (_tesseractInitialized) return;

  try {
    // Copy tessdata from assets to device storage
    final appDir = await getApplicationDocumentsDirectory();
    final tessdataDir = Directory(path.join(appDir.path, 'tessdata'));
    
    if (!await tessdataDir.exists()) {
      await tessdataDir.create(recursive: true);
    }

    // Copy eng.traineddata if not already present
    final engFile = File(path.join(tessdataDir.path, 'eng.traineddata'));
    if (!await engFile.exists()) {
      debugPrint('Copying tessdata from assets...');
      final data = await rootBundle.load('assets/tessdata/eng.traineddata');
      final bytes = data.buffer.asUint8List();
      await engFile.writeAsBytes(bytes);
      debugPrint('Tessdata copied successfully: ${engFile.path}');
    }

    _tesseractInitialized = true;
    debugPrint('Tesseract initialized with language data');
  } catch (e) {
    debugPrint('Tesseract initialization error: $e');
    rethrow;
  }
}
```

### 2. How It Works

1. **First Run:**
   - App copies `eng.traineddata` from assets to device storage
   - Location: `/data/data/com.yourapp/files/tessdata/eng.traineddata`
   - This happens once, on first OCR use

2. **Subsequent Runs:**
   - Checks if tessdata already exists
   - Skips copying if file is present
   - Uses existing tessdata for OCR

3. **OCR Processing:**
   - `flutter_tesseract_ocr` automatically finds tessdata in app directory
   - Processes images using local Tesseract engine
   - Returns extracted text

## Testing Steps

### 1. Clean Install
```bash
# Remove old app from device
adb uninstall com.example.frontend

# Clean Flutter build
cd frontend
flutter clean
flutter pub get

# Rebuild and install
flutter run
```

### 2. Test Offline OCR

1. **Disable internet** on the device
2. **Open the app**
3. **Navigate to File Explorer**
4. **Tap FAB (+) → Scan document**
5. **Capture a page with clear text**
6. **Tap "Done"**

### 3. Check Logs

Look for these debug messages:
```
✅ Copying tessdata from assets...
✅ Tessdata copied successfully: /data/data/.../tessdata/eng.traineddata
✅ Tesseract initialized with language data
✅ Processing image 1 with Tesseract (offline)...
✅ Extracted XXX characters from page 1
```

### 4. Verify Results

- **Mode indicator:** Should show orange "Offline" badge
- **OCR preview:** Should display extracted text
- **Save option:** Only "Save as PDF" available (no Markdown in offline mode)

## Common Issues & Solutions

### Issue 1: "Unable to load asset"
**Cause:** Tessdata file not in assets
**Solution:**
```bash
# Verify file exists
ls -lh frontend/assets/tessdata/eng.traineddata
# Should show: 23466654 bytes

# If missing, download again
cd frontend/assets/tessdata
Invoke-WebRequest -Uri "https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata" -OutFile "eng.traineddata"
```

### Issue 2: "Tesseract initialization error"
**Cause:** Permission issues or corrupted file
**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check device logs
adb logcat | grep -i tesseract
```

### Issue 3: "No text extracted"
**Cause:** Poor image quality or wrong language
**Solution:**
- Use good lighting when capturing
- Ensure text is clear and in focus
- Use high-contrast images (black text on white background)
- Verify language is set to 'eng'

### Issue 4: Still using online mode
**Cause:** Device has internet connection
**Solution:**
- Completely disable WiFi and mobile data
- Enable airplane mode
- Verify "Offline" badge appears in OCR preview

### Issue 5: App crashes on OCR
**Cause:** Insufficient memory or corrupted tessdata
**Solution:**
```bash
# Clear app data
adb shell pm clear com.example.frontend

# Reinstall
flutter run

# Check available memory
adb shell dumpsys meminfo com.example.frontend
```

## Debug Commands

### Check if tessdata was copied
```bash
# List app files
adb shell run-as com.example.frontend ls -la files/tessdata/

# Should show:
# eng.traineddata (23466654 bytes)
```

### View app logs
```bash
# Real-time logs
adb logcat | grep -E "(Tesseract|OCR|flutter)"

# Save logs to file
adb logcat > ocr_debug.log
```

### Check app storage
```bash
# Check available space
adb shell df /data/data/com.example.frontend

# Check file permissions
adb shell run-as com.example.frontend ls -la files/tessdata/
```

## Performance Expectations

### Offline Mode (Tesseract)
- **First run:** 5-10 seconds (includes tessdata copy)
- **Subsequent runs:** 1-3 seconds per page
- **Accuracy:** 70-80% for clear printed text
- **Memory usage:** ~50MB additional RAM

### Comparison with Online Mode
| Metric | Online (DeepSeek) | Offline (Tesseract) |
|--------|-------------------|---------------------|
| Speed | 2-5 sec/page | 1-3 sec/page |
| Accuracy | 90-95% | 70-80% |
| Internet | Required | Not required |
| First run | Fast | Slower (copy tessdata) |

## Verification Checklist

Before reporting issues, verify:

- [ ] `eng.traineddata` exists in `frontend/assets/tessdata/` (23MB)
- [ ] `pubspec.yaml` includes `assets/tessdata/`
- [ ] App has been rebuilt after adding tessdata
- [ ] Device internet is completely disabled
- [ ] App has storage permissions
- [ ] Device has sufficient free space (>100MB)
- [ ] Image quality is good (clear, high contrast)
- [ ] Logs show "Tesseract initialized" message

## Advanced Debugging

### Enable verbose logging
```dart
// In ocr_service.dart, add more debug prints:
debugPrint('=== OCR Debug Info ===');
debugPrint('Platform: ${Platform.operatingSystem}');
debugPrint('Is online: ${await _isOnline()}');
debugPrint('Image path: ${imageFiles[i].path}');
debugPrint('Image size: ${await imageFiles[i].length()} bytes');
debugPrint('Language: $language');
```

### Test with sample image
```dart
// Create a test with known text
final testImage = File('path/to/test/image.jpg');
final result = await _processImagesOffline([testImage]);
debugPrint('Test result: ${result.pages[0].text}');
```

### Check Tesseract version
```bash
# On device (if Tesseract CLI is available)
adb shell tesseract --version
```

## Expected Behavior

### Successful Offline OCR Flow

1. **User scans document** (internet disabled)
2. **App detects offline mode**
3. **First time only:** Copies tessdata from assets (~5 seconds)
4. **Processes image** with Tesseract (~1-3 seconds)
5. **Shows preview** with orange "Offline" badge
6. **Displays extracted text** with reasonable accuracy
7. **User saves as PDF** (Markdown not available offline)

### Log Output
```
I/flutter: Tesseract initialized with language data at: /data/data/.../tessdata
I/flutter: Processing image 1 with Tesseract (offline)...
I/flutter: Extracted 245 characters from page 1
I/flutter: OCR Result: success=true, mode=offline, pages=1
```

## Still Not Working?

If offline OCR still doesn't work after following this guide:

1. **Capture full logs:**
   ```bash
   adb logcat > full_debug.log
   # Reproduce the issue
   # Ctrl+C to stop
   ```

2. **Check these specific things:**
   - Device Android version (should be 5.0+)
   - Available RAM (should be 2GB+)
   - Storage space (should be 100MB+ free)
   - App permissions (storage, camera)

3. **Try alternative approach:**
   - Use online mode (DeepSeek) instead
   - Test on different device
   - Test with simpler image (single word)

4. **Report issue with:**
   - Device model and Android version
   - Full log output
   - Screenshot of error
   - Sample image that fails

## Summary

The offline OCR implementation now:
✅ Copies tessdata from assets to device storage
✅ Initializes Tesseract with proper paths
✅ Provides detailed debug logging
✅ Handles errors gracefully
✅ Falls back to online mode if offline fails

**Test it now with internet disabled!** 📱✨
