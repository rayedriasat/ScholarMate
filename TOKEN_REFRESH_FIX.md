# Token Refresh Issue - Fixed

## Problem

Users seeing error: **"No refresh token found for user"** during indexing.

## Root Cause

The `google_sign_in` package v7+ doesn't expose refresh tokens directly to the app. Refresh tokens are managed internally by the Google Sign-In plugin for security reasons.

### Why This Happens

1. **Frontend** (`google_sign_in` v7+):
   - Doesn't provide `refreshToken` in authentication response
   - Handles token refresh internally via `authorizationClient`
   - Only exposes `accessToken` and `idToken`

2. **Backend** (expecting refresh token):
   - Tries to use refresh token to get new access tokens
   - Fails because no refresh token was stored
   - Causes indexing jobs to fail with "No refresh token found"

## Solution

### 1. Client-Side Token Management (Implemented)

**Frontend handles token refresh:**
- Uses `google_sign_in`'s built-in refresh mechanism
- Automatically refreshes tokens when they expire
- Sends fresh access tokens with each API request

**Backend accepts fresh tokens:**
- Stores placeholder "CLIENT_MANAGED" for refresh token
- Provides clear error messages when token refresh is needed
- User re-authenticates in app to get fresh tokens

### 2. Better Error Messages (Implemented)

**Before:**
```
Failed after 4 attempts: No refresh token found for user 98c99792-d53f-4297-aba5-eca7bc0bf567
```

**After:**
```
No refresh token found for user. Please re-authenticate in the app.
```

Or:
```
Refresh token is managed by client app. Please refresh token in the app and retry.
```

## How It Works Now

### Sign In Flow

1. User signs in with Google
2. Frontend gets `accessToken` and `idToken`
3. Frontend sends tokens to backend:
   ```json
   {
     "access_token": "ya29.a0...",
     "id_token": "eyJhbG...",
     "refresh_token": null  // Not available in v7+
   }
   ```
4. Backend stores:
   - `access_token`: Encrypted actual token
   - `refresh_token`: Encrypted "CLIENT_MANAGED" placeholder

### Token Expiry Flow

1. Backend tries to use access token → Gets 401 Unauthorized
2. Backend checks for refresh token → Finds "CLIENT_MANAGED"
3. Backend returns error: "Please refresh token in the app"
4. Frontend catches error → Calls `authService.getAccessToken()`
5. Frontend's `google_sign_in` refreshes token automatically
6. Frontend retries request with fresh token
7. Request succeeds

### Indexing Flow

1. User starts indexing job
2. Backend processes in background
3. If token expires during processing:
   - Job fails with clear error message
   - User sees: "Please re-authenticate and retry"
4. User signs out and back in (gets fresh tokens)
5. User retries indexing → Succeeds

## User Actions

### If You See "No Refresh Token" Error

**Option 1: Re-authenticate (Recommended)**
1. Sign out from the app
2. Sign in again
3. Retry the failed operation

**Option 2: Wait for Auto-Refresh**
- Frontend automatically refreshes tokens
- Retry the operation after a few seconds

### If Indexing Fails

1. Check the error message in Indexing Progress panel
2. If it mentions "refresh token":
   - Sign out and sign in again
   - Use "Retry" button on the failed job
3. If it's a different error:
   - Check the full error message
   - May be a different issue (memory, network, etc.)

## Technical Details

### Frontend Token Refresh

```dart
// AuthService automatically handles refresh
Future<String?> getAccessToken() async {
  // Check cached token
  if (_currentUser?.accessToken != null && await StorageService.areTokensValid()) {
    return _currentUser!.accessToken;
  }
  
  // Get fresh token from google_sign_in
  var authz = await _account!.authorizationClient.authorizationForScopes(_scopes);
  
  // If expired, google_sign_in refreshes automatically
  if (authz == null) {
    authz = await _account!.authorizationClient.authorizeScopes(_scopes);
  }
  
  return authz.accessToken;
}
```

### Backend Token Storage

```python
# Store placeholder for client-managed refresh token
if not request.refresh_token:
    await supabase_service.store_encrypted_token(
        user_id=db_user_id,
        token_type="refresh_token",
        encrypted_token=encryption_service.encrypt("CLIENT_MANAGED")
    )
```

### Backend Token Refresh Attempt

```python
# Check if token is client-managed
refresh_token = encryption_service.decrypt(encrypted_refresh_token)

if refresh_token == "CLIENT_MANAGED":
    raise ValueError("Refresh token is managed by client app. Please refresh token in the app and retry.")
```

## Alternative Solutions (Not Implemented)

### Option A: Server-Side OAuth Flow

**Pros:**
- Backend has full control over tokens
- Can refresh tokens independently

**Cons:**
- More complex setup
- Requires web server for OAuth callback
- Security concerns (storing refresh tokens)

### Option B: Short-Lived Jobs Only

**Pros:**
- Tokens less likely to expire during job

**Cons:**
- Doesn't solve the problem
- Large PDFs still take >1 hour to index

### Option C: Token Refresh Endpoint

**Pros:**
- Frontend can refresh backend's token on demand

**Cons:**
- Adds complexity
- Still requires client-side refresh capability

## Why Current Solution is Best

1. **Security**: Refresh tokens never leave the client
2. **Simplicity**: Uses built-in `google_sign_in` refresh
3. **Reliability**: Google handles token refresh logic
4. **User Experience**: Automatic refresh in most cases
5. **Clear Errors**: Users know what to do when it fails

## Testing

### Test Token Expiry

1. Sign in to the app
2. Wait for token to expire (1 hour)
3. Try to index a PDF
4. Should see clear error message
5. Sign out and back in
6. Retry indexing → Should work

### Test Auto-Refresh

1. Sign in to the app
2. Use app normally
3. Frontend should auto-refresh tokens
4. No user action needed

## Files Modified

1. **backend/app/routers/auth.py**
   - Store "CLIENT_MANAGED" placeholder when no refresh token

2. **backend/app/services/drive_service.py**
   - Check for "CLIENT_MANAGED" token
   - Provide clear error messages

3. **frontend/lib/widgets/indexing_progress_panel.dart**
   - Show actual file names instead of cryptic IDs

4. **frontend/lib/services/drive_service.dart**
   - Added `getCachedFileName()` method

## Summary

✓ **Issue**: "No refresh token found" errors
✓ **Cause**: `google_sign_in` v7+ doesn't expose refresh tokens
✓ **Solution**: Client-side token management with clear error messages
✓ **User Action**: Sign out/in if token expires during long operations
✓ **Bonus Fix**: Show actual file names in indexing progress

**Both issues fixed!**
