# Android Authentication Persistence - Solution Applied

## Problem

On Windows, the app maintains login state across app restarts (24+ hours). On Android, the app forced re-login after approximately 1 hour.

## Root Cause

The `google_sign_in_all_platforms` package behaves differently per platform:

| Platform | `silentSignIn()` Behavior |
|----------|---------------------------|
| **Windows/Desktop** | Uses `saveAccessToken`/`retrieveAccessToken` callbacks → Persistent |
| **Android/iOS** | Uses in-memory cache only → Lost when app killed |

## Solution Applied

### 1. Added Token Persistence Callbacks (auth_service.dart)

```dart
_googleSignIn = GoogleSignIn(
  params: GoogleSignInParams(
    // ... other params ...
    saveAccessToken: _saveAccessToken,
    retrieveAccessToken: _retrieveAccessToken,
    deleteAccessToken: _deleteAccessToken,
  ),
);
```

These callbacks store/retrieve the token JSON to `SharedPreferences`, enabling session restoration on Android.

### 2. Use Actual Token Expiry (auth_service.dart)

Now using `credentials.expiresIn` (v2.0.0 feature) instead of hardcoded 1-hour assumption:

```dart
DateTime tokenExpiry;
if (credentials.expiresIn != null) {
  tokenExpiry = credentials.expiresIn!;
} else if (userInfo.containsKey('exp') && userInfo['exp'] is int) {
  tokenExpiry = DateTime.fromMillisecondsSinceEpoch(userInfo['exp'] * 1000);
} else {
  tokenExpiry = DateTime.now().add(const Duration(hours: 1));
}
```

### 3. Updated StorageService

Changed from hardcoded `_tokenValidityDuration` to `_defaultTokenValidityDuration` as fallback only.

## Files Modified

- `frontend/lib/services/auth_service.dart` - Added persistence callbacks, use actual expiry
- `frontend/lib/services/storage_service.dart` - Use actual expiry time

## Expected Behavior After Fix

1. User signs in on Android
2. Credentials saved to SharedPreferences via `_saveAccessToken`
3. App is killed/restarted
4. On startup, `silentSignIn()` calls `_retrieveAccessToken`
5. Stored credentials restored → User stays logged in
6. No popup, no re-login required

## Test

1. Build new APK: `flutter build apk`
2. Install and sign in
3. Force close app completely
4. Reopen app
5. Should go directly to HomeScreen without login
