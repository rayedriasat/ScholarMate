# Metadata Extraction Troubleshooting Guide

## Error: "Failed to extract metadata from PDF"

### Step 1: Check if Backend is Running

**Start the backend:**
```bash
cd backend
uv run python run.py
```

You should see output like:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**Test the backend health:**
Open in browser: http://localhost:8000/api/metadata/health

Should return: `{"status":"ok","service":"metadata"}`

### Step 2: Check Console Logs

**Frontend Console (Browser DevTools):**
Look for these log messages:
- `Extracting metadata for file: [filename]`
- `API URL: [url]`
- `Metadata extraction response status: [code]`

**Backend Console:**
Look for these log messages:
- `Extracting metadata for file: [filename]`
- `Fetching file bytes from Google Drive...`
- `Successfully fetched [X] bytes`
- `Extracted metadata: title=[title]`

### Step 3: Common Error Messages

#### "Cannot connect to backend. Is it running?"
- **Cause:** Backend is not running or wrong URL
- **Solution:** Start backend with `cd backend && uv run python run.py`
- **Check:** Verify `frontend/dart_defines.json` has correct `API_BASE_URL`

#### "Request timed out. Backend may not be running."
- **Cause:** Backend is slow or not responding
- **Solution:** Check backend console for errors
- **Check:** Ensure backend dependencies are installed: `cd backend && uv sync`

#### "Authentication error. Please sign in again."
- **Cause:** Invalid or expired authentication token
- **Solution:** Sign out and sign in again in the app

#### "File not found in Google Drive"
- **Cause:** File doesn't exist or user doesn't have access
- **Solution:** Verify file exists in Google Drive and user has access

### Step 4: Verify Dependencies

**Backend dependencies:**
```bash
cd backend
uv sync
```

**Check pypdf is installed:**
```bash
cd backend
uv run python -c "import pypdf; print('pypdf version:', pypdf.__version__)"
```

Should output: `pypdf version: 6.1.3` (or higher)

### Step 5: Test with a Simple PDF

1. Create a test PDF with embedded metadata
2. Upload to Google Drive
3. Open in ScholarMate
4. Click the info icon (ⓘ)
5. Check console logs for detailed error messages

### Step 6: Manual API Test

**Using curl:**
```bash
curl -X POST "http://localhost:8000/api/metadata/extract?user_id=YOUR_USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "file_id": "YOUR_FILE_ID",
    "file_name": "test.pdf",
    "extract_from_content": true
  }'
```

Replace:
- `YOUR_USER_ID`: Your Google user ID (from auth)
- `YOUR_TOKEN`: Your ID token (from auth)
- `YOUR_FILE_ID`: Google Drive file ID

### Expected Behavior

**Minimum metadata (always returned):**
- File name
- File size
- File ID

**Additional metadata (if available in PDF):**
- Title
- Authors
- Publication year
- DOI, ISBN, PMID, arXiv ID
- Journal/Conference
- Abstract
- Keywords

### Debug Mode

The app now logs detailed information:

**Frontend logs show:**
- API endpoint being called
- Authentication status
- Response status and body
- Parsing results

**Backend logs show:**
- File fetch from Google Drive
- PDF parsing process
- Metadata extraction results
- Any errors with stack traces

### Still Having Issues?

1. Check both frontend and backend console logs
2. Copy the exact error message
3. Verify backend is accessible at the configured URL
4. Test with different PDF files
5. Ensure all dependencies are installed
6. Check Google Drive API permissions
