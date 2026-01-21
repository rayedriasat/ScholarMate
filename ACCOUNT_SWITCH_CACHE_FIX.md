# Account Switch Cache Fix - Summary

## Problem
When logging out from one Google account and logging into another Google account on Windows, the Files Library view showed no files, and file uploads threw errors. The issue persisted until the app was closed and restarted.

**Root Cause:** The local cache (file metadata, PDFs, and Drive folder IDs) was not being cleared when switching accounts. The new user would inherit the old user's cached data, causing mismatches and errors.

## Solution Implemented

### 1. **User Switch Detection**
Added logic to detect when a different user signs in by comparing user IDs in:
- `_windowsSignIn()` - Windows client-side login
- `_handleAuthStateChange()` - Auth state change listener
- `_exchangeCodeForSession()` - Backend OAuth flow
- `silentSignIn()` - Silent sign-in restoration

When a different user is detected, a flag `_cache_clear_needed` is set in StorageService.

### 2. **Cache Clearing on Logout**
Updated the `signOut()` and `forceLogout()` methods to set the `_cache_clear_needed` flag before signing out.

### 3. **App-Level Cache Clearing**
Modified `main.dart` to listen to auth state changes and automatically clear the cache when:
- A user logs out (user becomes null)
- The `_cache_clear_needed` flag is set (indicating a user switch)

The following are cleared:
- `CacheService.clearAllCache()` - Clears all file metadata, PDFs, thumbnails, and annotations from the local database
- `DriveService.clearAppFolderCache()` - Clears the cached app folder ID

### 4. **Cache is Reset to Zero**
When a new user logs in:
1. All old cache is cleared
2. The cache starts fresh at zero
3. New files are fetched from the new user's Google Drive
4. Cache builds up as the user interacts with files

## Files Modified

### 1. `frontend/lib/services/auth_service.dart`
- Updated `_windowsSignIn()` to detect user switches
- Updated `_handleAuthStateChange()` to detect user switches and set cache clear flag
- Updated `_exchangeCodeForSession()` to detect user switches in backend OAuth flow
- Updated `silentSignIn()` to detect user switches during restoration
- Updated `signOut()` to set cache clear flag
- Updated `forceLogout()` to set cache clear flag
- Added comments explaining cache clearing strategy

### 2. `frontend/lib/main.dart`
- Added `StorageService` import
- Updated auth state listener in `_initializeApp()` to:
  - Check for `_cache_clear_needed` flag
  - Clear cache on user logout
  - Clear cache when switching users
  - Remove the flag after clearing

## How It Works

### Scenario 1: User Logs Out and Logs Back In (Same User)
1. User clicks "Sign Out"
2. `signOut()` sets `_cache_clear_needed = true`
3. Auth state changes to `null`
4. Main.dart listener detects logout and clears cache
5. User signs in again with same account
6. Fresh data is loaded from Google Drive
7. Cache rebuilds with current user's files

### Scenario 2: User Switches to Different Account
1. User clicks "Sign Out"
2. `signOut()` sets `_cache_clear_needed = true`
3. Auth state changes to `null`
4. Main.dart listener detects logout and clears cache
5. User signs in with different Google account
6. `_windowsSignIn()` detects different user ID
7. Fresh data is loaded from new user's Google Drive
8. Cache rebuilds with new user's files

### Scenario 3: Silent Sign-In Detects Different User
1. App starts and attempts silent sign-in
2. `silentSignIn()` detects different user ID (comparing to stored user)
3. Sets `_cache_clear_needed = true`
4. Auth state changes to new user
5. Main.dart listener detects flag and clears cache
6. Fresh data is loaded from new user's Google Drive

## Testing Instructions

### Test 1: Basic Account Switch
1. **Login with User A:**
   - Open the app
   - Sign in with Google Account A
   - Upload a file named "UserA_File.pdf"
   - Verify the file appears in the Files Library

2. **Logout:**
   - Sign out from the app
   - Verify you're back at the login screen

3. **Login with User B:**
   - Sign in with Google Account B (different account)
   - **IMPORTANT:** The Files Library should show User B's files, NOT User A's files
   - Upload a file named "UserB_File.pdf"
   - Verify the upload succeeds without errors
   - Verify only User B's files are visible

4. **Verify Cache is Clean:**
   - User A's files should NOT be visible
   - User B should see only their own files
   - No errors should occur during file operations

### Test 2: Rapid Account Switching
1. Sign in with User A
2. Upload a file
3. Sign out
4. Sign in with User B
5. Upload a file (should succeed)
6. Sign out
7. Sign in with User A again
8. Verify User A sees only their files (not User B's)

### Test 3: App Restart (Verify No Regression)
1. Sign in with User A
2. Upload files
3. Close the app completely
4. Restart the app
5. User A should be auto-signed in (if refresh token is valid)
6. User A's files should be visible
7. This should work as before (no regression)

### Test 4: Silent Sign-In with Different User
1. Sign in with User A
2. Close the app
3. Manually change the stored credentials to User B (advanced test)
4. Restart the app
5. App should detect different user during silent sign-in
6. Cache should be cleared
7. User B's files should be loaded

## Expected Behavior After Fix

✅ **Files Library shows correct files immediately after login**
✅ **No need to restart the app to see new user's files**
✅ **File uploads work correctly after account switch**
✅ **Cache is cleared automatically on logout**
✅ **Cache is cleared automatically when different user is detected**
✅ **No interference between different user accounts**

## Debug Logging

The fix includes comprehensive debug logging. Look for these messages in the console:

```
Different user detected (old: <old_id>, new: <new_id>), clearing cache...
Clearing cache (user logged out/switched)...
Cache cleared successfully
```

## Additional Notes

### Why Not Clear Cache in AuthService?
We clear the cache at the app level (main.dart) to avoid circular dependencies. The AuthService doesn't depend on CacheService or DriveService, maintaining clean architecture.

### Why Use a Flag Instead of Direct Clearing?
The `_cache_clear_needed` flag allows the cache clearing to happen asynchronously in the auth state listener, ensuring it happens at the right time in the app lifecycle and has access to the required services.

### What About Android/Web?
The same logic applies to Android and Web platforms through the backend OAuth flow (`_exchangeCodeForSession`). The fix is cross-platform.

## Rollback Plan

If any issues occur, you can revert the changes by:
1. Restoring the original `auth_service.dart` from git history
2. Restoring the original `main.dart` from git history
3. The fix is isolated to these two files and can be safely reverted

## Performance Impact

**Minimal:** Cache clearing only happens on login/logout, not during normal app usage. The performance impact is negligible and is already expected during authentication flows.

## Security Considerations

✅ **Improved:** Users can no longer see cached data from other accounts
✅ **Improved:** File metadata is properly isolated per user
✅ **No Change:** Token security remains the same

---

**Status:** ✅ Implementation Complete  
**Testing Required:** Yes - Manual testing on Windows platform  
**Breaking Changes:** None  
**Migration Required:** None
