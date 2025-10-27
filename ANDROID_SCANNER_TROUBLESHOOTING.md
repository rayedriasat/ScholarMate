# Android Document Scanner Troubleshooting

## Issue: Can't proceed after capturing images

### Changes Made

1. **Improved Button Visibility**
   - Changed from `TextButton` to `ElevatedButton` with green background
   - Made button more prominent and easier to tap
   - Added padding for better touch target

2. **Added Debug Logging**
   - Added print statements throughout the process
   - Logs will show in console when running `flutter run`
   - Helps identify where the process is failing

3. **Better Error Handling**
   - Added try-catch around dialog dismissal
   - Added stack trace logging
   - More descriptive error messages

### How to Debug

1. **Run the app with console output:**
   ```bash
   cd frontend
   flutter run
   ```

2. **Watch for these log messages:**
   - `🔵 _processAndSave called with X images` - Button was tapped
   - `🔵 Getting services from context...` - Services loading
   - `🔵 Showing processing dialog...` - Dialog shown
   - `🔵 Starting OCR processing...` - OCR started
   - `🔵 OCR processing complete: true/false` - OCR finished
   - `🔵 Showing OCR preview...` - Preview dialog shown
   - `🔵 User chose to save: true/false` - User decision
   - `🔵 Preparing to upload: filename` - Upload starting
   - `🔵 Uploading to Drive...` - Upload in progress
   - `🔵 Upload complete, caching metadata...` - Upload done
   - `❌ Error in _processAndSave: ...` - If error occurs

3. **Check for errors:**
   - Look for red error messages in console
   - Check if backend is running and accessible
   - Verify network connectivity

### Common Issues and Solutions

#### 1. Button Not Visible
**Symptom:** Can't see the "Done" button
**Solution:** 
- Button now has green background and is more prominent
- Only shows when images are captured
- Check if `_capturedImages.isNotEmpty`

#### 2. Button Not Responding
**Symptom:** Button visible but nothing happens when tapped
**Solution:**
- Check console for `🔵 _processAndSave called` message
- If no message, button tap not registering
- Try tapping in center of button
- Ensure `_isProcessing` is false

#### 3. OCR Service Not Available
**Symptom:** Error about OCR service
**Solution:**
- Ensure backend is running: `cd backend && uv run python run.py`
- Check backend URL in `.env` file
- Test OCR health: `http://localhost:8000/api/ocr/health`
- Verify Tesseract is installed

#### 4. Network Connection Issues
**Symptom:** Can't connect to backend
**Solution:**
- On Android emulator: Use `10.0.2.2:8000` instead of `localhost:8000`
- On physical device: Use computer's IP address (e.g., `192.168.1.100:8000`)
- Update `frontend/.env`:
  ```
  API_BASE_URL=http://10.0.2.2:8000  # For emulator
  # OR
  API_BASE_URL=http://192.168.1.100:8000  # For physical device
  ```

#### 5. Drive Upload Fails
**Symptom:** Error during upload to Drive
**Solution:**
- Ensure user is logged in
- Check Drive permissions
- Verify parent folder ID is valid
- Check network connectivity

#### 6. Camera Permission Issues
**Symptom:** Camera won't open
**Solution:**
- Check `AndroidManifest.xml` has camera permissions
- Grant camera permission in device settings
- Use gallery picker as alternative

### Testing Steps

1. **Start Backend:**
   ```bash
   cd backend
   uv run python run.py
   ```

2. **Verify Backend:**
   ```bash
   curl http://localhost:8000/api/ocr/health
   ```
   Should return: `{"status": "healthy", "available": true}`

3. **Update Frontend Config (if needed):**
   Edit `frontend/.env`:
   ```
   # For Android Emulator
   API_BASE_URL=http://10.0.2.2:8000
   
   # For Physical Device (replace with your computer's IP)
   # API_BASE_URL=http://192.168.1.100:8000
   ```

4. **Run Flutter App:**
   ```bash
   cd frontend
   flutter run
   ```

5. **Test Scanner:**
   - Navigate to file explorer
   - Tap FAB (+) button
   - Tap "Scan document" (camera icon)
   - Capture or select images
   - Look for green "Done" button in top right
   - Tap "Done" button
   - Watch console for log messages
   - Check for any errors

### Expected Flow

1. ✅ Capture/select images
2. ✅ Images appear in horizontal list at bottom
3. ✅ Green "Done (X)" button appears in top right
4. ✅ Tap "Done" button
5. ✅ "Processing OCR..." dialog appears
6. ✅ OCR processes images (may take a few seconds)
7. ✅ "OCR Preview" dialog shows extracted text
8. ✅ Tap "Save" to continue
9. ✅ "Uploading to Drive..." dialog appears
10. ✅ File uploads to Drive
11. ✅ Success message shown
12. ✅ Return to file explorer

### Network Configuration for Android

#### Android Emulator
The emulator uses a special IP to access the host machine:
- `10.0.2.2` = Your computer's localhost
- So `http://10.0.2.2:8000` = `http://localhost:8000` on your computer

#### Physical Android Device
Must use your computer's actual IP address:
1. Find your computer's IP:
   - Windows: `ipconfig` (look for IPv4 Address)
   - Mac/Linux: `ifconfig` or `ip addr`
2. Use that IP in the app: `http://YOUR_IP:8000`
3. Ensure both devices on same WiFi network
4. Ensure firewall allows port 8000

### Quick Fix Checklist

- [ ] Backend is running
- [ ] Backend OCR health check passes
- [ ] Frontend `.env` has correct `API_BASE_URL`
- [ ] App has camera permissions
- [ ] User is logged in
- [ ] Network connectivity working
- [ ] Can see green "Done" button after capturing images
- [ ] Console shows log messages when button tapped

### Still Not Working?

1. **Restart everything:**
   ```bash
   # Stop backend (Ctrl+C)
   # Stop app (Ctrl+C)
   
   # Clear Flutter build
   cd frontend
   flutter clean
   flutter pub get
   
   # Restart backend
   cd ../backend
   uv run python run.py
   
   # Restart app
   cd ../frontend
   flutter run
   ```

2. **Check console output carefully:**
   - Look for the 🔵 blue circle emoji messages
   - Look for ❌ red X emoji error messages
   - Note where the process stops

3. **Test backend directly:**
   ```bash
   cd backend
   uv run python test_ocr_with_image.py
   ```

4. **Verify services are registered:**
   - Check `frontend/lib/main.dart`
   - Ensure `OCRService` is in providers list

### Contact/Debug Info to Provide

If still having issues, provide:
1. Console output (all 🔵 and ❌ messages)
2. Backend logs
3. Android version
4. Emulator or physical device?
5. Network configuration (localhost, IP, etc.)
6. Any error messages shown in app
