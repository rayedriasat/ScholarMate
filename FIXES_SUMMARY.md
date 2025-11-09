# Fixes Summary - Token Refresh & File Names

## Issues Fixed

### 1. ✓ Refresh Token Error

**Problem:**
```
Failed after 4 attempts: No refresh token found for user 98c99792-d53f-4297-aba5-eca7bc0bf567
```

**Root Cause:**
- `google_sign_in` v7+ doesn't expose refresh tokens
- Tokens are managed internally by the plugin
- Backend was expecting refresh tokens that don't exist

**Solution:**
- Store "CLIENT_MANAGED" placeholder for refresh token
- Provide clear error messages when token refresh is needed
- User re-authenticates in app to get fresh tokens

**User Action:**
- If you see "No refresh token" error:
  1. Sign out from the app
  2. Sign in again
  3. Retry the failed operation

### 2. ✓ Cryptic File Names in Indexing Progress

**Problem:**
```
File: 1YIZ_SoQ...
```

**Root Cause:**
- UI was displaying file ID instead of file name
- Code: `job.fileId.substring(0, 8)...`

**Solution:**
- Added `getCachedFileName()` method to DriveService
- UI now fetches actual file name from cache
- Falls back to shortened ID if name not found

**Result:**
```
document.pdf
research_paper.pdf
```

## Files Modified

### Backend

1. **backend/app/routers/auth.py**
   - Store "CLIENT_MANAGED" placeholder when no refresh token provided
   - Log when using client-side token management

2. **backend/app/services/drive_service.py**
   - Check for "CLIENT_MANAGED" token
   - Provide clear error: "Please re-authenticate in the app"
   - Provide clear error: "Refresh token is managed by client app"

### Frontend

3. **frontend/lib/services/drive_service.dart**
   - Added `getCachedFileName(String fileId)` method
   - Returns file name from cache or null

4. **frontend/lib/widgets/indexing_progress_panel.dart**
   - Use `FutureBuilder` to fetch file name asynchronously
   - Display actual file name instead of file ID
   - Fallback to shortened ID if name not available

## Testing

### Test Token Refresh Fix

1. **Sign in to app**
2. **Start indexing a PDF**
3. **If token expires:**
   - Should see clear error message
   - Sign out and back in
   - Retry indexing → Should work

### Test File Name Display

1. **Upload some PDFs**
2. **Start indexing**
3. **Open Indexing Progress panel**
4. **Verify:**
   - Shows actual file names (e.g., "document.pdf")
   - Not cryptic IDs (e.g., "1YIZ_SoQ...")

## Before & After

### Indexing Progress Panel

**Before:**
```
File: 1YIZ_SoQ...
Failed • just now
Failed after 4 attempts: No refresh token found for user 98c99792-d53f-4297-aba5-eca7bc0bf567
```

**After:**
```
research_paper.pdf
Failed • just now
No refresh token found for user. Please re-authenticate in the app.
```

## Documentation

- **TOKEN_REFRESH_FIX.md** - Detailed explanation of token refresh issue
- **FIXES_SUMMARY.md** - This file

## Next Steps

1. **Deploy fixes:**
   ```bash
   git add .
   git commit -m "Fix token refresh error + show file names in indexing progress"
   git push origin main
   ```

2. **Test in production:**
   - Sign in and start indexing
   - Verify file names display correctly
   - If token expires, verify clear error message

3. **User communication:**
   - If users see "refresh token" error:
     - Tell them to sign out and back in
     - Retry the operation

## Summary

✓ **Token Refresh**: Clear error messages, user knows what to do
✓ **File Names**: Shows actual names instead of cryptic IDs
✓ **User Experience**: Much better error handling and UI clarity

**Both issues fixed and ready to deploy!**
