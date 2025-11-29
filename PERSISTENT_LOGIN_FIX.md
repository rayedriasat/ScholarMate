# Persistent Login & Drive Scope Access Fix

## Problem Summary

Your authentication was expiring frequently because:

1. **No refresh token strategy**: The app wasn't properly requesting or using OAuth2 refresh tokens
2. **Missing offline access**: Google wasn't providing refresh tokens without `accessType: 'offline'`
3. **No automatic token refresh**: When tokens expired, the app didn't automatically refresh them
4. **Silent failures**: Drive API calls failed with 401 but didn't trigger token refresh

## Solution Implemented

### 1. Leverage Platform-Specific Token Storage

**File: `frontend/lib/services/auth_service.dart`**

The `google_sign_in_all_platforms` library automatically:
- Stores refresh tokens in platform-specific secure storage (Keychain on iOS/macOS, Credential Manager on Windows, etc.)
- Handles token refresh internally when you call `silentSignIn()`
- Maintains persistent login across app restarts

**Key insight**: You don't need to manually manage refresh tokens - the library does it for you through `silentSignIn()`.

### 2. Implement Proper Token Refresh

Added `refreshAccessTokenWithRefreshToken()` method as a fallback that:
- Makes direct OAuth2 token refresh request to Google
- Uses refresh token to get new access token
- Updates user object and storage with new token
- Stores updated token in backend

**Token Refresh Strategy**:
1. **Primary**: Use `silentSignIn()` (recommended by library - handles refresh internally)
2. **Fallback**: Use manual refresh token if `silentSignIn()` fails

### 3. Automatic Token Refresh in getAccessToken()

The `getAccessToken()` method now:
- Checks if token expires in next 5 minutes
- Automatically refreshes before expiry
- Prevents multiple simultaneous refresh attempts
- Returns fresh token transparently

### 4. Drive API Helper with Auto-Retry

**New File: `frontend/lib/services/drive_api_helper.dart`**

Provides authenticated HTTP methods that:
- Automatically add Authorization header
- Detect 401 Unauthorized responses
- Force token refresh on 401
- Retry request with new token
- Support GET, POST, PATCH, DELETE

**Usage Example**:
```dart
final helper = DriveApiHelper(authService);
final response = await helper.authenticatedGet(
  Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId'),
);
// Automatically handles token refresh if needed
```

### 5. Backend Error Handling

**File: `backend/app/services/drive_service.py`**

Updated to return specific error codes:
- `TOKEN_EXPIRED` - Frontend should refresh token
- `INSUFFICIENT_SCOPE` - User needs to re-authorize with correct scopes

## How It Works Now

### Initial Sign-In Flow
1. User clicks "Sign In"
2. Google OAuth consent screen appears
3. User grants permissions (including drive.file scope)
4. `google_sign_in_all_platforms` receives credentials and stores refresh token in platform secure storage
5. App receives:
   - Access token (expires in ~1 hour)
   - ID token (user info)
   - Refresh token (stored internally by the library)
6. Access token and user info stored locally and in backend

### Token Refresh Flow (Automatic)
1. App checks token expiry before each Drive API call
2. If token expires in <5 minutes:
   - Calls `silentSignIn()` which automatically uses stored refresh token
   - Library fetches new access token from Google
   - Updates storage and backend
   - Returns new token
3. Drive API call proceeds with fresh token

### 401 Error Recovery
1. Drive API call returns 401 Unauthorized
2. `DriveApiHelper` detects 401
3. Forces token refresh via `getAccessToken(forceRefresh: true)`
4. This triggers `silentSignIn()` to get fresh token
5. Retries request with new token
6. Success (or shows error if refresh fails)

## Migration Steps

### For Existing Users

The `google_sign_in_all_platforms` library stores refresh tokens in platform-specific secure storage automatically. If users are experiencing frequent logouts:

1. **Clear app data** (on mobile) or **sign out and sign in again** to ensure fresh credentials
2. The library will automatically store refresh tokens in secure storage
3. Subsequent `silentSignIn()` calls will use these stored tokens

### For New Users

No action needed - the library handles everything automatically on first sign-in.

## Using DriveApiHelper

Update your Drive service to use the helper:

```dart
class DriveService {
  final DriveApiHelper _apiHelper;
  
  DriveService(AuthService authService) 
    : _apiHelper = DriveApiHelper(authService);
  
  Future<List<DriveFile>> listFiles() async {
    final response = await _apiHelper.authenticatedGet(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Process files...
    }
  }
  
  Future<Uint8List> downloadFile(String fileId) async {
    final response = await _apiHelper.authenticatedGet(
      Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media'),
    );
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Download failed');
  }
}
```

## Testing Checklist

- [ ] Sign in with Google
- [ ] Verify refresh token is stored (check logs)
- [ ] Access Drive files successfully
- [ ] Wait 1 hour (or manually expire token in storage)
- [ ] Access Drive files again - should auto-refresh
- [ ] Close app and reopen - should stay signed in
- [ ] Restart device - should stay signed in
- [ ] Check logs for "Token refreshed successfully using refresh token"

## Troubleshooting

### "Silent sign-in failed to return valid credentials"
- Platform secure storage may be corrupted
- Solution: Sign out and sign in again to refresh stored credentials

### "Token refresh failed"
- Refresh token may be revoked or expired
- Solution: Sign out and sign in again

### "INSUFFICIENT_SCOPE" error
- User didn't grant drive.file scope during initial sign-in
- Solution: Sign out, sign in, and accept all permissions

### Still getting 401 errors
- Check if `DriveApiHelper` is being used for all Drive API calls
- Verify scopes include `'https://www.googleapis.com/auth/drive.file'`
- Check backend logs for specific error messages
- Try signing out and signing in again to refresh credentials

### Tokens expire too quickly
- This is normal - access tokens expire in ~1 hour
- The fix ensures automatic refresh happens transparently
- If refresh fails repeatedly, check platform secure storage permissions

## Key Files Modified

1. `frontend/lib/services/auth_service.dart` - Token refresh logic
2. `frontend/lib/services/drive_api_helper.dart` - NEW - Auto-retry helper
3. `backend/app/services/drive_service.py` - Better error codes

## Benefits

✅ **Persistent login** - Users stay signed in indefinitely
✅ **Automatic token refresh** - No manual intervention needed
✅ **Graceful error recovery** - Auto-retry on 401 errors
✅ **Offline-first compatible** - Works with cached tokens
✅ **Secure** - Refresh tokens stored in platform secure storage
✅ **Cross-platform** - Works on all platforms (Android, iOS, Web, Windows, macOS, Linux)
