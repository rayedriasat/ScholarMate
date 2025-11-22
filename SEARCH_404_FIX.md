# Fix Search 404 Error

## Problem

Getting error: `Search failed: {"error":{"message":"Not Found","status_code":404}}`

## Root Cause

The backend needs to be restarted to load the new search router.

## Solution

### Step 1: Stop Backend

In the terminal running the backend, press **Ctrl+C** to stop it.

### Step 2: Restart Backend

```bash
cd backend
uv run python run.py
```

You should see:
```
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Step 3: Verify Search Endpoint

Open browser to: `http://localhost:8000/docs`

Scroll down and look for **Search** section with `/api/search/` endpoint.

### Step 4: Test Search

In the app:
1. Go to Files tab
2. Tap search icon (🔍)
3. Enter a query like "test"
4. Disable "Include content search" (for faster test)
5. Tap Search

## If Still Getting 404

### Check Backend URL

The frontend might be pointing to wrong URL. Check `frontend/dart_defines.json`:

```json
{
  "BACKEND_URL": "http://localhost:8000"
}
```

For Android emulator, use:
```json
{
  "BACKEND_URL": "http://10.0.2.2:8000"
}
```

For physical device, use your computer's IP:
```json
{
  "BACKEND_URL": "http://192.168.x.x:8000"
}
```

### Check Backend Logs

When you search, backend should log:
```
INFO: Search request from user <user-id>: 'test' (max: 20, semantic: False)
```

If you don't see this, the request isn't reaching the backend.

### Test Backend Directly

From command line:

```bash
curl -X POST http://localhost:8000/api/search/ \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"test\", \"user_id\": \"test-user\", \"max_results\": 10, \"include_semantic\": false}"
```

Expected response:
```json
{
  "results": [...],
  "total_count": 0,
  "query": "test",
  "search_time_ms": 50
}
```

## Alternative: Hot Reload

If using `run.py` with auto-reload, you can just save `backend/app/main.py` to trigger reload:

1. Open `backend/app/main.py`
2. Add a space somewhere
3. Save
4. Backend should reload automatically

## Common Issues

### Issue: Backend won't start

**Error:** `ModuleNotFoundError: No module named 'requests'`

**Fix:**
```bash
cd backend
uv sync
uv run python run.py
```

### Issue: Port already in use

**Error:** `Address already in use`

**Fix:**
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Then restart
uv run python run.py
```

### Issue: CORS error

**Error:** `Access-Control-Allow-Origin`

**Fix:** Add your frontend URL to `backend/.env`:
```
DEBUG=true
```

This allows all origins in development.

## Verification Checklist

- [ ] Backend is running on port 8000
- [ ] `/api/search/` appears in http://localhost:8000/docs
- [ ] Frontend `BACKEND_URL` is correct
- [ ] Search button appears in Files tab
- [ ] Search screen opens when tapped
- [ ] Backend logs show search requests

## Quick Test

**Minimal test without semantic search:**

1. Restart backend
2. Open app
3. Go to Files tab
4. Tap search (🔍)
5. Enter: "test"
6. Uncheck "Include content search"
7. Tap Search

This should work even without Pinecone/indexing.

## Need More Help?

Check backend logs for specific error:
```bash
cd backend
uv run python run.py
```

Look for errors when you try to search.
