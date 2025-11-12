# ✅ Google Sub ID Fix Complete

## The Problem

The error "invalid input syntax for type uuid" was happening because:
- Frontend sends Google sub claim (numeric string like `103136320510419145687`)
- Backend expected UUID format
- Database query failed

## The Solution

I've updated `backend/app/services/api_key_service.py` to automatically convert Google sub claims to UUIDs.

### Changes Made

Added `_resolve_user_id()` method that:
1. Checks if ID is already a UUID (has dashes, 36 chars)
2. If not, looks up the UUID from the `users` table using `google_sub`
3. Creates a minimal user record if not found
4. Returns the UUID for database queries

All methods now use this resolver:
- ✅ `create_or_update_key()`
- ✅ `get_user_keys()`
- ✅ `get_key()`
- ✅ `delete_key()`
- ✅ `update_key_status()`
- ✅ `get_active_provider()`
- ✅ `log_usage()`
- ✅ `get_usage_stats()`

## How to Apply the Fix

### Option 1: Restart Backend (Recommended)

```bash
# Stop current backend (Ctrl+C in terminal)
# Then restart:
cd backend
uv run python run.py
```

### Option 2: Force Reload

If the backend is still showing the error after restart:

```bash
# Kill all Python processes
Get-Process python | Stop-Process -Force

# Clear Python cache
Remove-Item -Recurse -Force backend/app/__pycache__
Remove-Item -Recurse -Force backend/app/services/__pycache__

# Restart backend
cd backend
uv run python run.py
```

## Test the Fix

```bash
# Test with Google sub ID (should work now)
curl http://192.168.0.101:8000/api/keys/103136320510419145687

# Should return:
# {"keys": [], "total": 0}
# Instead of UUID error
```

## In Your Flutter App

1. **Restart the backend** (see above)
2. **Hot reload** your Flutter app (press 'r' in terminal)
3. Go to **Settings → API Keys**
4. Error should be gone! ✅
5. Tap **"+ Add Key"** to add your first key

## Why This Happened

The RAG service already had this Google sub → UUID conversion logic, but the API key service didn't. Now both services handle Google sub IDs correctly.

## Verification

After restarting the backend, you should see in logs:
```
INFO: Fetching API keys for user 103136320510419145687
# No more UUID error!
```

## Next Steps

1. ✅ Restart backend
2. ✅ Test API Keys screen (should load without error)
3. ✅ Add a GROQ key (free from https://console.groq.com)
4. ✅ Test RAG queries with your own key

---

**Status**: ✅ Fix complete, just needs backend restart!
