# DriveService Fix - Authentication Compatibility

## Issues Fixed

After migrating to `google_sign_in_all_platforms`, the `DriveService` had compatibility issues with the new `AuthService` API.

### Errors Found
1. **Line 47**: `The method 'refreshToken' isn't defined for the type 'AuthService'`
2. **Line 49**: `The operand can't be 'null', so the condition is always 'false'` (warning)
3. **Line 49**: `Dead code` (warning)
4. **Line 70**: `The method 'refreshToken' isn't defined for the type 'AuthService'`

### Root Cause

The old `AuthService` (using `google_sign_in ^7.2.0`) had a public `refreshToken()` method that `DriveService` was calling when tokens expired. The new `AuthService` (using `google_sign_in_all_platforms ^2.0.2`) doesn't expose this method because:

1. Token refresh is handled automatically by the `getAccessToken()` method
2. The package manages token lifecycle internally
3. `silentSignIn()` is the proper way to restore/refresh sessions

### Changes Made

#### 1. Updated `_getAccessToken()` method

**Before:**
```dart
Future<String> _getAccessToken() async {
  var accessToken = await _authService.getAccessToken();

  if (accessToken == null) {
    debugPrint('No access token available, attempting to refresh...');
    accessToken = await _authService.refreshToken(); // ❌ Method doesn't exist

    if (accessToken == null) {
      throw Exception('No access token available. Please sign in again.');
    }
  }

  return accessToken;
}
```

**After:**
```dart
Future<String> _getAccessToken() async {
  // First try to get current token (automatically refreshes if expired)
  var accessToken = await _authService.getAccessToken();

  if (accessToken == null) {
    debugPrint('No access token available, attempting silent sign-in...');
    
    // Try silent sign-in to restore session
    final user = await _authService.silentSignIn(); // ✅ Use silentSignIn()
    accessToken = user?.accessToken;

    if (accessToken == null) {
      throw Exception('No access token available. Please sign in again.');
    }
  }

  return accessToken;
}
```

#### 2. Updated `_makeAuthenticatedRequest()` method

**Before:**
```dart
// If unauthorized, try to refresh token and retry once
if (response.statusCode == 401) {
  debugPrint('Access token expired, refreshing...');

  final newToken = await _authService.refreshToken(); // ❌ Method doesn't exist
  if (newToken != null) {
    response = await requestFunction(newToken);
  } else {
    throw Exception('Unable to refresh access token. Please sign in again.');
  }
}
```

**After:**
```dart
// If unauthorized, try to refresh token and retry once
if (response.statusCode == 401) {
  debugPrint('Access token expired, attempting to refresh...');

  // Try silent sign-in to get fresh token
  final user = await _authService.silentSignIn(); // ✅ Use silentSignIn()
  if (user?.accessToken != null) {
    response = await requestFunction(user!.accessToken!);
  } else {
    throw Exception('Unable to refresh access token. Please sign in again.');
  }
}
```

## How It Works Now

### Token Refresh Flow

1. **Initial Request**: `DriveService` calls `_getAccessToken()`
2. **Check Cache**: `AuthService.getAccessToken()` checks if cached token is valid
3. **Auto-Refresh**: If expired, `getAccessToken()` automatically refreshes via `silentSignIn()`
4. **Return Token**: Fresh token is returned to `DriveService`

### 401 Error Handling

1. **Request Fails**: Google Drive API returns 401 (token invalid/expired)
2. **Silent Sign-In**: `DriveService` calls `AuthService.silentSignIn()`
3. **Get New Token**: `silentSignIn()` restores session and returns fresh credentials
4. **Retry Request**: `DriveService` retries the request with new token

### Benefits

- ✅ **Automatic Token Management**: Tokens refresh automatically without manual intervention
- ✅ **Better Error Handling**: More graceful recovery from token expiration
- ✅ **Consistent API**: All services use the same token refresh mechanism
- ✅ **Long-Term Access**: Backend maintains Drive access via refresh tokens
- ✅ **User-Friendly**: No repeated sign-in prompts for token issues

## Verification

All linter errors are now resolved:
```bash
flutter analyze
# No errors in auth_service.dart or drive_service.dart
```

## Related Files

- `frontend/lib/services/auth_service.dart` - New authentication service
- `frontend/lib/services/drive_service.dart` - Fixed to use new API
- `GOOGLE_SIGN_IN_ALL_PLATFORMS_MIGRATION.md` - Full migration guide
- `AUTHENTICATION_QUICK_START.md` - Quick start guide

## Testing

To test the fixes:

1. **Sign in**: User signs in with Google
2. **Use Drive**: Access Google Drive files (creates ScholarMate folder)
3. **Wait for Token Expiry**: Let token expire (~1 hour)
4. **Access Drive Again**: Should automatically refresh without errors
5. **Verify**: Check logs for "Access token expired, attempting to refresh..." message

## Notes

- The `google_sign_in_all_platforms` package handles token refresh internally
- `silentSignIn()` is the proper way to restore sessions and refresh tokens
- No need for a separate `refreshToken()` method - it's all automatic
- Backend will receive updated tokens on each refresh

