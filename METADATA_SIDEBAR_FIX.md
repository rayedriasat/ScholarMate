# Metadata Sidebar Fix - "No metadata available"

## Problem
The File Metadata Sidebar was showing "No metadata available" for all PDFs.

## Root Cause
The backend `extract_from_pdf_info()` method had a missing return statement in the exception handler, causing it to return `None` instead of fallback metadata when errors occurred.

## Solution

### Backend Fixes (`backend/app/services/metadata_service.py`)
- Fixed missing return statement in `extract_from_pdf_info()` error handler
- Added comprehensive logging throughout metadata extraction
- Ensured fallback metadata (at minimum: filename, file_id, file_size) is always returned

### Backend Router (`backend/app/routers/metadata.py`)
- Added detailed logging to track the extraction process
- Added error stack traces for better debugging

### Frontend Fixes (`frontend/lib/widgets/file_metadata_sidebar.dart`)
- Improved error handling to detect when API returns `null`
- Added specific error messages with retry functionality
- Added console logging for debugging

### Frontend Service (`frontend/lib/services/metadata_service.dart`)
- Added detailed logging for API calls and responses
- Added stack traces for error debugging

## Testing
1. Start backend: `cd backend && uv run python run.py`
2. Start frontend: `cd frontend && flutter run -d chrome`
3. Open any PDF file
4. Click the info icon (ⓘ) to open metadata sidebar
5. Check console logs for detailed extraction process

## Expected Results
- Sidebar will show at least basic metadata (filename, size, dates)
- If PDF has embedded metadata, it will be displayed
- If extraction fails, a clear error message with retry button appears
- Console logs show the complete extraction process for debugging

## Notes
- Some PDFs have no embedded metadata - this is normal
- The system now always returns at least minimal metadata
- All errors are logged for debugging
