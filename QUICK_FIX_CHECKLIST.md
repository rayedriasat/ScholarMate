# Quick Fix Checklist - Metadata Extraction

## Immediate Actions

### 1. Start the Backend (if not running)
```bash
cd backend
uv run python run.py
```

Wait for: `INFO: Uvicorn running on http://0.0.0.0:8000`

### 2. Verify Backend is Accessible
Open in browser: http://localhost:8000/api/metadata/health

Expected response: `{"status":"ok","service":"metadata"}`

### 3. Check Frontend Configuration
File: `frontend/dart_defines.json`

Ensure it has:
```json
{
  "API_BASE_URL": "http://localhost:8000"
}
```

### 4. Restart Frontend (if needed)
```bash
cd frontend
flutter run -d chrome
```

### 5. Test the Metadata Sidebar

1. Open any PDF in the app
2. Click the info icon (ⓘ) in the toolbar
3. The sidebar should now show:
   - **If metadata exists:** Title, authors, year, etc.
   - **If no metadata:** At least file name, size, and dates
   - **If error:** Specific error message with retry button

### 6. Check Console Logs

**Browser Console (F12):**
- Look for "Extracting metadata for file:"
- Check for any error messages
- Note the response status code

**Backend Terminal:**
- Look for "Extracting metadata for file:"
- Check for "Successfully fetched X bytes"
- Look for any Python errors

## What Changed

### Better Error Handling
- Frontend now shows specific error messages
- Backend always returns at least minimal metadata
- Added timeout handling (30 seconds)

### Improved Logging
- Detailed logs in both frontend and backend
- Stack traces for debugging
- Request/response tracking

### Fallback Display
- Shows basic file info even if metadata extraction fails
- No more blank "No metadata available" message

## Common Issues & Solutions

| Error Message | Solution |
|--------------|----------|
| "Cannot connect to backend" | Start backend: `cd backend && uv run python run.py` |
| "Request timed out" | Check backend console for errors |
| "Authentication error" | Sign out and sign in again |
| "File not found" | Verify file exists in Google Drive |

## Expected Results

**Every PDF should now show at least:**
- ✓ File name
- ✓ File size
- ✓ Created date
- ✓ Modified date

**PDFs with embedded metadata will also show:**
- ✓ Title
- ✓ Authors
- ✓ Publication year
- ✓ DOI, ISBN, or other identifiers
- ✓ Abstract (if available)
- ✓ Keywords (if available)

## Still Not Working?

1. **Check backend is running:** `curl http://localhost:8000/api/metadata/health`
2. **Check console logs:** Look for specific error messages
3. **Verify dependencies:** `cd backend && uv sync`
4. **Test with different PDFs:** Some PDFs have more metadata than others
5. **Check authentication:** Make sure you're signed in

## Next Steps

If you're still seeing "failed to extract metadata from pdf":
1. Copy the exact error from the browser console
2. Copy any errors from the backend terminal
3. Share both for more specific debugging
