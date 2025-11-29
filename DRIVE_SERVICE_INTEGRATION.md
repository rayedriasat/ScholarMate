# DriveService Integration Guide

## Good News!

Your `DriveService` already has token refresh logic via `_makeAuthenticatedRequest()`. This is working correctly and handles 401 errors with automatic retry.

## Current Implementation (Already Working)

Your `_makeAuthenticatedRequest` method:
1. Gets access token (with auto-refresh if expired)
2. Makes the API call
3. If 401 error, forces token refresh and retries
4. Throws clear error if session is revoked

**This is already correct!** The auth fixes I made will improve this further.

## Two Options

### Option 1: Keep Current Implementation (Recommended)

Your current code is fine. The auth fixes I made will automatically improve it:

- `_getAccessToken()` now benefits from better token refresh logic
- `silentSignIn()` now works more reliably
- Manual refresh token fallback added

**No changes needed to DriveService!**

### Option 2: Migrate to DriveApiHelper (Optional)

If you want cleaner, more reusable code, you can replace `_makeAuthenticatedRequest` with `DriveApiHelper`:

**Before:**
```dart
final response = await _makeAuthenticatedRequest(
  (token) => http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  ),
);
```

**After:**
```dart
final response = await _apiHelper.authenticatedGet(
  Uri.parse(url),
  headers: {'Content-Type': 'application/json'},
);
```

**Benefits:**
- Less boilerplate code
- Consistent error handling across all services
- Easier to test

**Migration Steps:**

1. Add DriveApiHelper to DriveService:

```dart
import 'drive_api_helper.dart';

class DriveService extends ChangeNotifier {
  final AuthService _authService;
  final CacheService? _cacheService;
  final ConnectivityService? _connectivityService;
  late final DriveApiHelper _apiHelper; // ADD THIS
  
  DriveService({
    AuthService? authService,
    CacheService? cacheService,
    ConnectivityService? connectivityService,
  }) : _authService = authService ?? AuthService(),
       _cacheService = cacheService,
       _connectivityService = connectivityService {
    _apiHelper = DriveApiHelper(_authService); // ADD THIS
  }
  
  // ... rest of code
}
```

2. Replace `_makeAuthenticatedRequest` calls:

```dart
// OLD:
final response = await _makeAuthenticatedRequest(
  (token) => http.get(
    Uri.parse(searchUrl),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  ),
);

// NEW:
final response = await _apiHelper.authenticatedGet(
  Uri.parse(searchUrl),
  headers: {'Content-Type': 'application/json'},
);
```

3. Remove `_getAccessToken()` and `_makeAuthenticatedRequest()` methods (no longer needed)

## Recommendation

**Stick with Option 1** (keep current implementation). Your code is already working correctly, and the auth fixes I made will automatically improve it. Only migrate to `DriveApiHelper` if you want cleaner code or are refactoring anyway.

## What Actually Fixed Your Issue

The real fixes were in `auth_service.dart`:

1. **Better token expiry checking** - Refreshes 5 minutes before expiry instead of waiting for 401
2. **Improved silentSignIn() usage** - Properly leverages platform secure storage
3. **Manual refresh token fallback** - Uses OAuth2 refresh if silentSignIn fails
4. **Better error handling** - Clear messages when session is revoked

Your DriveService will automatically benefit from these improvements without any changes!

## Testing

1. Sign in to your app
2. Use any Drive feature (list files, upload, download)
3. Check logs for token refresh messages
4. Wait 55+ minutes and try again - should auto-refresh
5. Should see: `"Token expiring, attempting refresh..."` → `"Access token refreshed successfully"`

## Summary

✅ Your DriveService is already correct
✅ Auth fixes will automatically improve it
✅ No changes required
✅ DriveApiHelper is optional for cleaner code
