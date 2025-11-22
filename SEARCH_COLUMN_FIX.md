# Search Column Name Fix

## Problem

Getting error: `column files.modified_at does not exist`

## Root Cause

The code has been updated but the backend hasn't reloaded the changes.

## Solution

### Step 1: Force Backend Restart

**Stop the backend** (Ctrl+C), then restart:

```bash
cd backend
uv run python run.py
```

### Step 2: Verify the Fix

The search service now uses correct column names:
- ✓ `size_bytes` (not `size`)
- ✓ `drive_modified_time` (not `modified_at`)

### Step 3: Test Search

1. Open app
2. Go to Files tab
3. Tap search icon (🔍)
4. Enter any query (e.g., "test")
5. **Uncheck** "Include content search"
6. Tap Search

Should work now!

## If Still Failing

### Check Backend Logs

Look for the actual query being executed:

```
INFO: Search query for user <user-id>: 'test' (semantic: False)
INFO: Found X files for user
```

If you see an error about `modified_at`, the backend didn't reload.

### Manual Verification

Check the file directly:

```bash
cd backend
grep "modified_at" app/services/search_service.py
```

Should return **nothing**. If it shows results, the file wasn't saved correctly.

### Nuclear Option: Clear Python Cache

```bash
cd backend
# Windows
del /s /q __pycache__
del /s /q *.pyc

# Then restart
uv run python run.py
```

## Expected Behavior

**Working search:**
```
Query: "research"
Results:
- Research Paper.pdf (EXACT - 100%)
- My Research.pdf (PARTIAL - 85%)
- Paper on Research.pdf (FUZZY - 60%)
```

**No results:**
```
Query: "xyz123"
Results: 0 results
(This is normal if no files match)
```

## Quick Test

Try searching for a file you know exists:
1. Note a filename from your Files tab
2. Search for part of that name
3. Should appear in results

## Still Not Working?

Check these:
1. Backend is running: `http://localhost:8000/docs`
2. Search endpoint exists: Look for `/api/search/` in Swagger
3. User has files in Supabase
4. Backend URL is correct in `dart_defines.json`
