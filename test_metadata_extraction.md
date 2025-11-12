# Testing Metadata Extraction

## Issue
The File Metadata Sidebar is showing "No metadata available" for all PDFs.

## Changes Made

### Frontend Changes
1. **file_metadata_sidebar.dart**: Improved error handling to show specific error messages when metadata extraction fails
2. **metadata_service.dart**: Added detailed logging to track API calls and responses

### Backend Changes
1. **metadata.py**: Added comprehensive logging to track the extraction process
2. **metadata_service.py**: 
   - Fixed missing return statement in error handling
   - Added detailed logging for debugging
   - Ensured fallback metadata is always returned

## How to Test

1. **Start the backend** (if not already running):
   ```bash
   cd backend
   uv run python run.py
   ```

2. **Start the frontend** (if not already running):
   ```bash
   cd frontend
   flutter run -d chrome
   ```

3. **Open a PDF** in the app

4. **Click the info icon** (ⓘ) in the toolbar to open the metadata sidebar

5. **Check the console logs**:
   - Frontend console (browser DevTools) will show:
     - API URL being called
     - Response status
     - Response body
     - Parsed metadata
   
   - Backend console will show:
     - File being fetched from Google Drive
     - Bytes received
     - Metadata extraction process
     - Final metadata values

## Expected Behavior

The sidebar should now either:
- **Show metadata** if extraction succeeds (even if minimal - just filename and size)
- **Show a specific error message** if extraction fails, with a "Retry" button

## Common Issues

1. **Backend not running**: Check if backend is accessible at the configured URL
2. **Authentication issues**: Verify the user is logged in and token is valid
3. **File access issues**: Ensure the file exists in Google Drive and user has access
4. **PDF parsing errors**: Some PDFs may have no embedded metadata - this is normal

## Next Steps

If the issue persists after these changes:
1. Check the console logs for specific error messages
2. Verify the API endpoint is reachable
3. Test with different PDF files (some may have more metadata than others)
4. Check if the backend dependencies are installed (`uv sync`)
