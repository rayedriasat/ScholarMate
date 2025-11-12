# Restart Backend to Apply Fix

## The Fix
Fixed the UUID vs Google sub issue in the Supabase service. The backend now correctly handles Google sub IDs when looking up user tokens.

## How to Apply

### 1. Stop the Backend
If the backend is running, stop it with `Ctrl+C` in the terminal

### 2. Restart the Backend
```bash
cd backend
uv run python run.py
```

Wait for:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### 3. Test the Metadata Sidebar
1. Open any PDF in the app
2. Click the info icon (ⓘ) in the toolbar
3. The metadata sidebar should now load successfully

## What Changed
- `backend/app/services/supabase_service.py` - Added automatic Google sub → UUID lookup
- `backend/app/routers/metadata.py` - Improved error messages

## Expected Result
✓ Metadata sidebar shows file information
✓ No more "invalid input syntax for type uuid" error
✓ Backend logs show successful metadata extraction

## If It Still Doesn't Work
Check the backend console for any new error messages and share them.
