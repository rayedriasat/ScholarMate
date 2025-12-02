# Authentication Flow Fix - Persistent Login

## Problem

Users were experiencing repeated `AUTHENTICATION_EXPIRED` errors and being forced to re-login frequently. The Google Drive access would expire and not refresh automatically.

## Root Cause Analysis

1. **Incorrect Token Refresh Logic**: The old code tried to manually refresh tokens using `silentSignIn()` and `lightweightSignIn()`, but these methods restore cached credentials - they don't refresh expired tokens.

2. **Manual Refresh Token Flow Was Broken**: The `refreshAccessTokenWithRefreshToken()` method tried to manually call Google's OAuth endpoint, but `google_sign_in_all_platforms` manages refresh tokens internally and may not expose them.

3. **Not Using `authenticatedClient`**: The package provides `authenticatedClient` which handles token refresh automatically - this was not being used for Drive API calls.

4. **Unnecessary Backend Token Storage**: Tokens were being stored in the backend but never used for refresh, adding complexity without benefit.

## Solution

### Key Insight from Package Documentation

> "The `authenticatedClient` getter provides a ready-to-use HTTP client for Google APIs with automatic token management."
> - Token validation: Checks expiration before each use
> - Auto-refresh: Uses refresh tokens when available
> - Error recovery: Auto sign-out on unrecoverable failures

### Changes Made

#### 1. `auth_service.dart` - Simplified Authentication

- **Removed**: Manual token refresh logic, backend token storage calls
- **Added**: `getAuthenticatedClient()` method that returns the package's auto-refreshing HTTP client
- **Kept**: `silentSignIn()` on app startup to restore sessions (correct usage)

```dart
/// Get the authenticated HTTP client for Google API calls
/// This is the KEY method - the client handles token refresh automatically!
Future<http.Client?> getAuthenticatedClient() async {
  final client = await _googleSignIn!.authenticatedClient;
  if (client == null) {
    // Try to restore session
    final restored = await silentSignIn();
    if (restored != null) {
      return await _googleSignIn!.authenticatedClient;
    }
  }
  return client;
}
```

#### 2. `drive_service.dart` - Use Authenticated Client

- **Changed**: All Drive API calls now use `_getClient()` which gets the auto-refreshing client
- **Removed**: Manual token handling and refresh retry logic

```dart
Future<http.Client> _getClient() async {
  final client = await _authService.getAuthenticatedClient();
  if (client == null) {
    throw Exception('AUTHENTICATION_REQUIRED: Please sign in.');
  }
  return client;
}
```

#### 3. `api_service.dart` - Removed Token Storage

- **Removed**: `storeTokens()`, `refreshToken()`, `deleteTokens()` methods
- **Kept**: All other API methods (tags, indexing, AI chat)

#### 4. `backend/app/routers/auth.py` - Simplified

- **Changed**: Token endpoints now just store user metadata
- **Added**: Legacy endpoints for backward compatibility that do nothing

## How It Works Now

1. **App Startup**: `silentSignIn()` restores the previous session from platform secure storage
2. **API Calls**: `getAuthenticatedClient()` returns an HTTP client that automatically:
   - Validates token expiration before each request
   - Refreshes tokens using internally stored refresh tokens
   - Signs out on unrecoverable failures
3. **Sign In**: User clicks sign-in → `signIn()` → stores credentials in platform secure storage
4. **Sign Out**: Clears platform secure storage

## Platform Behavior

| Platform | Token Storage | Refresh Mechanism |
|----------|--------------|-------------------|
| Windows/Linux | Platform secure storage | `silentSignIn()` + internal refresh |
| Android/iOS | System keychain | `silentSignIn()` + internal refresh |
| Web | Browser storage | `signInButton()` + internal refresh |

## Testing

1. Sign in with Google
2. Use the app normally (browse files, open PDFs)
3. Wait for token to expire (~1 hour) or restart the app
4. Continue using the app - should work without re-login
5. If issues persist, check browser console/debug logs for errors

## Notes

- The package manages refresh tokens internally - we don't need to handle them
- `silentSignIn()` is for session restoration, not token refresh
- `authenticatedClient` is the correct way to make authenticated API calls
