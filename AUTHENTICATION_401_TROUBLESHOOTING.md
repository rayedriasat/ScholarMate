# Authentication 401 Error - Troubleshooting Guide

## Your Current Issue

Based on your logs:
```
Received 401 Unauthorized from Google Drive API, attempting to refresh token...
Unable to get fresh token, forcing silent sign-in...
Attempting silent sign-in...
Created user with token expiry: 2025-11-14 16:54:32.708138 (credentials.expiresIn was: 2025-11-14 09:52:39.823520Z)
Successfully stored user and tokens in backend: coderay231@gmail.com
Silent sign-in successful for user: coderay231@gmail.com
Silent sign-in successful, retrying request...
Auth state changed: coderay231@gmail.com
Request still failed after token refresh
```

**The Problem:** Even though silent sign-in is succeeding and obtaining tokens, Google Drive API is still rejecting the access token with a 401 Unauthorized error.

## Possible Root Causes

### 1. **OAuth Token Revoked or Invalid**
   - The Google OAuth session may have been revoked
   - This happens if:
     - User changed their Google password
     - User revoked app access in Google Account settings
     - OAuth client credentials changed
     - Token was obtained with different scopes

### 2. **Scope Mismatch**
   - The access token might not have the required Drive API scope
   - Required scope: `https://www.googleapis.com/auth/drive`

### 3. **OAuth Client Configuration Issue**
   - The OAuth client ID or secret might be incorrect
   - The redirect URI might not be properly configured in Google Console

### 4. **Token Not Properly Refreshing**
   - The `google_sign_in_all_platforms` package might not be properly refreshing tokens
   - The stored token might be corrupted

## Immediate Solution: Sign Out and Sign In Again

The app will now automatically detect this situation and show you a dialog prompting you to sign out and sign back in.

### Manual Steps:

1. **Sign Out**
   - Open the app
   - Go to Settings or Profile
   - Click "Sign Out"

2. **Sign In Again**
   - Click "Sign in with Google"
   - Complete the Google authentication flow
   - Grant all requested permissions

3. **Verify Access**
   - Navigate to the Files tab
   - Files should load successfully

## Why This Happens

### Token Lifecycle
Google OAuth access tokens have a complex lifecycle:

```
1. User signs in → Gets access token + refresh token
2. Access token expires (1 hour) → Refresh using refresh token
3. Refresh token valid (until revoked) → Get new access token
4. IF refresh token invalid → Must re-authenticate
```

### Silent Sign-In Limitation
The `google_sign_in_all_platforms` package's `silentSignIn()` method:
- ✅ Can restore a session if valid
- ✅ Can refresh expired access tokens  
- ❌ **Cannot** recover from revoked OAuth sessions
- ❌ **Cannot** fix scope mismatches
- ❌ **Cannot** obtain new tokens if OAuth client changed

When you see "Request still failed after token refresh", it means:
- The Google Sign-In SDK thinks everything is fine
- But Google Drive API rejects the token
- This requires a **full re-authentication**

## New Features Added to Help

### 1. Enhanced Logging
The app now logs:
- Access token presence and preview (first 20 chars)
- ID token presence
- Token expiry timestamps
- Whether credentials are valid

**Look for these logs:**
```
Created user with token expiry: 2025-11-14 16:54:32.708138 (credentials.expiresIn was: 2025-11-14 09:52:39.823520Z)
Access token present: true, preview: ya29.a0AfB_byBhGxQ...
ID token present: true
```

### 2. Automatic Detection
The app now detects when token refresh fails and shows a dialog:
```
┌─────────────────────────────────────┐
│  ⚠️ Session Expired                 │
│                                     │
│  Your Google authentication session │
│  has expired or been revoked.       │
│  Please sign out and sign back in   │
│  to continue using ScholarMate.     │
│                                     │
│  [Cancel]           [Sign Out]  │
└─────────────────────────────────────┘
```

### 3. Clear Error Messages
Instead of generic "UNAUTHENTICATED", you'll see:
```
AUTHENTICATION_EXPIRED: Your session has expired. Please sign out and sign in again to continue.
```

## Debugging Steps

### Step 1: Check Logs for Token Info
After signing in, check the logs for:
```
Access token present: true, preview: ya29.a0...
```

If you see:
```
Access token present: false, preview: EMPTY
WARNING: No access token in credentials! This will cause authentication failures.
```
**→ The OAuth flow is broken, check Google Console configuration**

### Step 2: Verify Google Console Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **Credentials**
3. Find your OAuth 2.0 Client ID
4. Verify:
   - ✅ Client ID matches `.env` file
   - ✅ Client Secret matches `.env` file  
   - ✅ Redirect URIs include: `http://localhost:3000`
   - ✅ Authorized JavaScript origins include your app URL

5. Navigate to **APIs & Services** → **Enabled APIs**
6. Verify:
   - ✅ Google Drive API is enabled
   - ✅ Google Sign-In API is enabled

### Step 3: Check Granted Scopes

The app requires these scopes:
```dart
'openid',
'profile',
'email',
'https://www.googleapis.com/auth/drive',
```

To verify what scopes were granted:
1. Go to https://myaccount.google.com/permissions
2. Find "ScholarMate" (or your app name)
3. Click to see granted permissions
4. Should show: "See, edit, create, and delete all of your Google Drive files"

If Drive access is not granted:
- Click "Remove Access"
- Sign in to the app again
- Make sure to grant all requested permissions

### Step 4: Test with Fresh OAuth Client

If the issue persists, try creating a new OAuth client:

1. In Google Cloud Console, create a new OAuth 2.0 Client ID
2. Configure with same redirect URIs
3. Update `.env` files with new credentials:
   ```
   GOOGLE_CLIENT_ID=new-client-id.apps.googleusercontent.com
   GOOGLE_CLIENT_SECRET=new-client-secret
   ```
4. Restart the backend
5. Rebuild the frontend
6. Sign in again

## Code Changes Made

### 1. `auth_service.dart`
- Added token validation in `silentSignIn()`
- Enhanced logging with token preview
- Detects empty/invalid tokens

### 2. `drive_service.dart`
- Better 401 error handling
- Clear error message: `AUTHENTICATION_EXPIRED`
- Logs when token refresh fails

### 3. `file_explorer_screen.dart`
- Added `_showAuthenticationExpiredDialog()`
- Detects authentication errors automatically
- Provides easy sign-out button

## Prevention

### For Users:
1. **Don't change Google password** without re-authenticating in the app
2. **Don't revoke app access** in Google Account settings
3. **Grant all permissions** when signing in

### For Developers:
1. **Don't change OAuth client** without user re-authentication
2. **Test token refresh** regularly
3. **Monitor 401 errors** in logs
4. **Add retry logic** with exponential backoff

## Expected Behavior After Fix

### Normal Flow:
1. App starts → User already signed in
2. Token expired → Silent refresh → Success
3. File viewer loads files

### Error Flow (Session Revoked):
1. App starts → User already signed in  
2. Token expired → Silent refresh → Gets token
3. API call → 401 Unauthorized
4. App shows dialog → User clicks "Sign Out"
5. User signs in again → Success

## Still Having Issues?

### Check These:

1. **Backend logs** - Is the backend receiving valid tokens?
   ```bash
   # Check backend logs
   cd backend
   python -m uvicorn app.main:app --reload --log-level debug
   ```

2. **Network inspection** - Use browser dev tools or Charles Proxy to see actual API requests

3. **Token endpoint** - Test token directly with curl:
   ```bash
   curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
        https://www.googleapis.com/drive/v3/about?fields=user
   ```
   
   If this returns 401, the token is invalid at the Google level.

4. **OAuth playground** - Test your OAuth flow at https://developers.google.com/oauthplayground/

## Quick Fix Commands

### Clean Rebuild (Desktop):
```bash
# Flutter
cd frontend
flutter clean
flutter pub get
flutter run -d windows

# Backend
cd backend
pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

### Clean Rebuild (Android):
```bash
cd frontend
flutter clean
flutter pub get
flutter build apk --debug
flutter install
```

## Contact/Support

If none of these solutions work, provide these details:
1. Full logs from app startup to error
2. Google Cloud Console OAuth configuration screenshot
3. Output from token curl test
4. Platform (Windows/Android/Web)
5. `google_sign_in_all_platforms` package version

The development team can then provide targeted assistance.

