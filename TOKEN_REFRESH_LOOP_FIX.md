# Token Refresh Loop Fix - File Viewer Authentication Issue

## Problem Summary

When opening the app after a long period (1+ hour), users would see:
- User successfully logged in (silent sign-in works)
- File viewer screen shows "Error loading files: UNAUTHENTICATED"
- Logs show repeated token refresh attempts:
  ```
  Access token expired, attempting to refresh...
  Attempting silent sign-in...
  Successfully stored user and tokens in backend
  Silent sign-in successful for user: coderay231@gmail.com
  Auth state changed: coderay231@gmail.com
  ```
  (This pattern repeats multiple times)

## Root Cause

The issue was caused by improper token expiry handling in the authentication flow:

### 1. **Invalid Token Expiry from Google Sign-In**
   - Line 350 in `auth_service.dart` was using `credentials.expiresIn` directly
   - The `google_sign_in_all_platforms` package's `expiresIn` property could be:
     - `null` 
     - An invalid date
     - Already expired
   - This meant tokens appeared expired immediately after refresh

### 2. **No Loop Prevention**
   - When a token was expired, `getAccessToken()` would call `silentSignIn()`
   - `silentSignIn()` would create a new user with invalid expiry
   - The next API call would see the token as expired again
   - Infinite loop of token refreshes

### 3. **Concurrent Refresh Attempts**
   - Multiple components (file explorer, etc.) could trigger token refresh simultaneously
   - No synchronization mechanism to prevent concurrent refreshes

## Solution Implemented

### 1. Fixed Token Expiry Calculation (`auth_service.dart`)

**Before:**
```dart
return User.fromGoogleSignIn(
  // ...
  tokenExpiry: credentials.expiresIn, // ❌ Could be null or invalid
);
```

**After:**
```dart
// Calculate token expiry (Google tokens typically expire in 1 hour)
// We set expiry to 50 minutes from now to trigger refresh before actual expiry
final tokenExpiry = DateTime.now().add(const Duration(minutes: 50));

debugPrint('Created user with token expiry: $tokenExpiry (credentials.expiresIn was: ${credentials.expiresIn})');

return User.fromGoogleSignIn(
  // ...
  tokenExpiry: tokenExpiry, // ✅ Always valid, 50 minutes from now
);
```

### 2. Added Token Refresh Loop Prevention

**New State Variables:**
```dart
// Token refresh tracking to prevent loops
DateTime? _lastTokenRefresh;
bool _isRefreshing = false;
```

**Enhanced `getAccessToken()` Method:**
- Prevents refresh if token was refreshed in last 10 seconds
- Prevents concurrent refresh attempts
- Better logging for debugging
- Returns current token if refresh is in progress

```dart
// Prevent refresh loop: Don't refresh if we just refreshed in the last 10 seconds
if (_lastTokenRefresh != null && now.difference(_lastTokenRefresh!).inSeconds < 10) {
  debugPrint('Token was recently refreshed (${now.difference(_lastTokenRefresh!).inSeconds}s ago), using current token');
  return _currentUser!.accessToken;
}

// Prevent concurrent refresh attempts
if (_isRefreshing) {
  debugPrint('Token refresh already in progress, waiting...');
  await Future.delayed(const Duration(milliseconds: 500));
  return _currentUser?.accessToken;
}
```

### 3. Improved Drive API Request Handling (`drive_service.dart`)

**Enhanced `_makeAuthenticatedRequest()` Method:**
- Better logging for 401 errors
- Tries to get fresh token before forcing new sign-in
- Detects if token refresh actually provided a new token
- Better error messages

```dart
if (response.statusCode == 401) {
  debugPrint('Received 401 Unauthorized from Google Drive API, attempting to refresh token...');
  
  // Try to get a fresh token (this will trigger silent sign-in if needed)
  final freshToken = await _authService.getAccessToken();
  
  if (freshToken != null && freshToken != accessToken) {
    debugPrint('Got fresh token, retrying request...');
    response = await requestFunction(freshToken);
  } else {
    // Force a new silent sign-in
    // ...
  }
}
```

## How Token Refresh Works Now

### Normal Flow (Token Valid)
1. File viewer calls `listFiles()`
2. DriveService calls `_getAccessToken()`
3. AuthService checks token expiry
4. Token is valid → returns immediately
5. API request succeeds

### Token Refresh Flow (Token Expired)
1. File viewer calls `listFiles()`
2. DriveService calls `_getAccessToken()`
3. AuthService detects expired token
4. AuthService checks `_lastTokenRefresh` (prevent loop)
5. AuthService sets `_isRefreshing = true` (prevent concurrent)
6. AuthService calls `silentSignIn()`
7. Google Sign-In returns fresh credentials
8. **New token created with expiry = now + 50 minutes**
9. Token stored locally and in backend
10. `_lastTokenRefresh` updated
11. `_isRefreshing = false`
12. Fresh token returned
13. API request succeeds

### If Token Still Invalid (401 from API)
1. DriveService receives 401 response
2. Calls `_authService.getAccessToken()` again
3. Loop prevention kicks in (within 10 seconds)
4. Returns current token anyway
5. If still 401, forces new `silentSignIn()`
6. If still fails → clear error message to user

## Testing the Fix

### Test Scenario 1: After 1+ Hour Idle
1. Sign in to the app
2. Wait 1+ hours (or close and wait)
3. Open the app
4. Navigate to Files tab
5. **Expected:** Files load successfully after brief token refresh
6. **Check logs:** Should see single token refresh, no loops

### Test Scenario 2: Multiple Concurrent Requests
1. Open the app after idle period
2. Navigate to Files tab
3. Quickly navigate between folders
4. **Expected:** Files load successfully
5. **Check logs:** Should see single token refresh, concurrent requests wait

### Test Scenario 3: Network Issues
1. Open the app after idle period
2. Turn off network briefly
3. Turn network back on
4. Navigate to Files tab
5. **Expected:** Either cached files or fresh files after token refresh

## Log Messages to Watch For

### Success Case
```
Created user with token expiry: 2024-11-14 15:30:00.000 (credentials.expiresIn was: null)
Silent sign-in successful for user: coderay231@gmail.com
Token refresh successful, new expiry: 2024-11-14 15:30:00.000
Got fresh token, retrying request...
```

### Loop Prevention in Action
```
Access token expired (expiry: 2024-11-14 14:30:00.000), attempting refresh...
Token was recently refreshed (5s ago), using current token
```

### Concurrent Request Handling
```
Token refresh already in progress, waiting...
```

## Files Modified

1. `frontend/lib/services/auth_service.dart`
   - Fixed `_createUserFromCredentials()` to calculate token expiry correctly
   - Enhanced `getAccessToken()` with loop prevention
   - Added `_lastTokenRefresh` and `_isRefreshing` tracking

2. `frontend/lib/services/drive_service.dart`
   - Improved `_makeAuthenticatedRequest()` error handling
   - Enhanced `_getAccessToken()` logging
   - Better 401 retry logic

## Additional Benefits

- **Better Debugging:** Enhanced logging makes it easy to diagnose auth issues
- **More Resilient:** Handles edge cases like null expiry, concurrent requests
- **Better UX:** Faster response when token is valid, no unnecessary refreshes
- **Prevents API Rate Limiting:** No more rapid-fire token refresh attempts

## Known Limitations

1. **Token expiry hardcoded to 50 minutes:** This works for Google OAuth tokens which expire in 1 hour, but isn't dynamic
2. **10-second loop prevention window:** May need adjustment based on real-world usage
3. **No proactive token refresh:** Token only refreshes when accessed, not before expiry

## Future Improvements

1. **Proactive Token Refresh Timer:** Refresh token 5 minutes before expiry in background
2. **Retry with Exponential Backoff:** For network failures
3. **Token Expiry from JWT:** Parse ID token to get actual expiry time
4. **Better Offline Support:** Clearer messaging when offline vs auth issues

## Conclusion

This fix resolves the token refresh loop issue by ensuring tokens always have valid expiry times and preventing rapid consecutive refresh attempts. The file viewer should now work reliably after the app has been idle for extended periods.

