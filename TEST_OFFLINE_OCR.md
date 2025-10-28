# Quick Test: Offline OCR

## Prerequisites
- Android device or emulator
- App installed: `flutter run`
- Tessdata bundled: `assets/tessdata/eng.traineddata` (23MB)

## Test Steps

### 1. Run Test Script (Recommended)
```bash
cd frontend
flutter run test_tessdata_copy.dart
```

**Expected output:**
```
Step 1: ✅ Asset found (22.4 MB)
Step 2: ✅ App dir: /data/data/.../files
Step 3: ✅ Directory created: .../tessdata
Step 4: ✅ File copied (22.4 MB)
Step 5: ✅ File verified successfully!

✅ TEST PASSED!
```

### 2. Test in Main App

#### A. Enable Airplane Mode
- Turn on airplane mode on device
- Verify no internet connection

#### B. Scan Document
1. Open app
2. Navigate to File Explorer
3. Tap FAB (+) → Scan document
4. Capture a page with clear text
5. Tap "Done"

#### C. Verify Offline Mode
**Look for:**
- 🟠 Orange "Offline" badge (not green "Online")
- Processing message
- OCR preview with extracted text

#### D. Check Logs
```bash
adb logcat | grep -E "(Tesseract|OCR)"
```

**Expected logs (first run):**
```
I/flutter: Copying tessdata from assets...
I/flutter: Tessdata copied successfully: /data/data/.../tessdata/eng.traineddata
I/flutter: Tesseract initialized with language data
I/flutter: Processing image 1 with Tesseract (offline)...
I/flutter: Extracted XXX characters from page 1
```

**Expected logs (subsequent runs):**
```
I/flutter: Tesseract initialized with language data
I/flutter: Processing image 1 with Tesseract (offline)...
I/flutter: Extracted XXX characters from page 1
```

## Success Criteria

✅ Test script passes all steps
✅ Orange "Offline" badge appears
✅ Text is extracted from image
✅ No errors in logs
✅ "Save as PDF" option available
✅ "Save as Markdown" option NOT available (offline only)

## Timing Expectations

### First Run (with tessdata copy)
- Tessdata copy: ~5 seconds
- OCR processing: 1-3 seconds
- **Total: ~6-8 seconds**

### Subsequent Runs
- OCR processing: 1-3 seconds
- **Total: ~1-3 seconds**

## Common Issues

### ❌ Green "Online" badge appears
**Problem:** Device has internet connection
**Solution:** Enable airplane mode, disable WiFi and mobile data

### ❌ Error: "Unable to load asset"
**Problem:** Tessdata not in assets
**Solution:**
```bash
ls frontend/assets/tessdata/eng.traineddata
# Should show 23466654 bytes
```

### ❌ Error: "Tesseract initialization error"
**Problem:** Copy failed or permissions issue
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### ❌ No text extracted
**Problem:** Poor image quality
**Solution:**
- Use good lighting
- Clear, focused image
- High contrast (black text on white)
- Try with printed text (not handwritten)

## Quick Debug Commands

### Check if tessdata was copied
```bash
adb shell run-as com.example.frontend ls -la files/tessdata/
# Should show: eng.traineddata (23466654 bytes)
```

### View real-time logs
```bash
adb logcat | grep -i tesseract
```

### Clear app data and retry
```bash
adb shell pm clear com.example.frontend
flutter run
```

## Sample Test Document

For consistent testing, use:
- Printed text (not handwritten)
- Black text on white paper
- Standard font (Arial, Times New Roman)
- Font size 12pt or larger
- Good lighting, no shadows
- Straight-on photo (not angled)

**Example text to test:**
```
The quick brown fox jumps over the lazy dog.
1234567890
```

## Expected Accuracy

### Good Conditions (70-80% accuracy)
- Printed text
- High contrast
- Good lighting
- Clear focus
- Standard fonts

### Poor Conditions (30-50% accuracy)
- Handwritten text
- Low contrast
- Poor lighting
- Blurry image
- Decorative fonts

## Comparison: Online vs Offline

| Feature | Online (DeepSeek) | Offline (Tesseract) |
|---------|-------------------|---------------------|
| Badge | 🟢 Green "Online" | 🟠 Orange "Offline" |
| Speed | 2-5 sec | 1-3 sec (after first run) |
| Accuracy | 90-95% | 70-80% |
| Internet | Required | Not required |
| Markdown | ✅ Available | ❌ Not available |
| First run | Fast | Slower (copy tessdata) |

## Final Verification

Run through this checklist:

1. **Test script passes:** ✅
   ```bash
   flutter run test_tessdata_copy.dart
   ```

2. **Airplane mode enabled:** ✅

3. **Scan document:** ✅

4. **Orange badge appears:** ✅

5. **Text extracted:** ✅

6. **Logs show success:** ✅
   ```
   I/flutter: Tesseract initialized with language data
   I/flutter: Extracted XXX characters from page 1
   ```

7. **Can save as PDF:** ✅

8. **Markdown option hidden:** ✅ (offline only)

## If All Tests Pass

🎉 **Offline OCR is working!**

You can now:
- Scan documents without internet
- Use OCR on Android devices offline
- Get 70-80% accuracy for printed text
- Save as searchable PDFs

## If Tests Fail

1. **Run test script** to isolate issue
2. **Check logs** for specific errors
3. **Review** OFFLINE_OCR_TROUBLESHOOTING.md
4. **Report issue** with:
   - Device model and Android version
   - Full log output
   - Screenshot of error
   - Test script results

## Next Steps

After successful testing:
1. Test with various document types
2. Test with different lighting conditions
3. Compare accuracy with online mode
4. Gather user feedback
5. Consider adding more languages

**Happy testing!** 📱✨
