# Authentication Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### 1. Install Dependencies
```bash
cd frontend
flutter pub get
```

### 2. Verify Configuration
Check `frontend/dart_defines.json`:
```json
{
  "GOOGLE_CLIENT_ID": "325415234543-menqofjbigrju70tbi7oab4p5ath82lc.apps.googleusercontent.com",
  "GOOGLE_CLIENT_SECRET": "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",
  "GOOGLE_REDIRECT_URI": "http://localhost:8080/auth/callback",
  "API_BASE_URL": "http://localhost:8000",
  "SUPABASE_URL": "https://rqyzgfgdsedvohxyyqho.supabase.co",
  "SUPABASE_ANON_KEY": "eyJhbGci..."
}
```

### 3. Ensure Google Cloud Console Setup
- ✅ OAuth 2.0 Client ID created (Web Application)
- ✅ Authorized redirect URI: `http://localhost:8000`
- ✅ Drive API enabled
- ✅ OAuth consent screen configured

### 4. Run the App

#### Web
```bash
flutter run -d chrome --dart-define-from-file=dart_defines.json
```

#### Windows
```bash
flutter run -d windows --dart-define-from-file=dart_defines.json
```

#### Android/iOS
```bash
flutter run -d <device> --dart-define-from-file=dart_defines.json
```

## 🎯 Expected Behavior

### First Sign-In

#### Web
1. Click Google's **official** sign-in button (provided by Google SDK)
2. Browser redirect or popup opens
3. Sign in with Google account
4. Grant Drive permissions
5. Redirected back to app
6. User is authenticated

#### Mobile/Desktop
1. Click **custom styled** "Sign in with Google" button
2. Native OAuth flow or browser opens
3. Sign in with Google account
4. Grant Drive permissions
5. Redirected back to app
6. User is authenticated

### Subsequent App Opens
1. App opens → User **automatically signed in** (no interaction needed)
2. Works offline (tokens cached locally)
3. Backend maintains Drive access via refresh tokens

### Sign Out
1. Click sign out
2. All tokens cleared (local + backend)
3. User must sign in again

## 🔧 Key Features

### ✅ Windows & Linux Support
- Uses default browser for OAuth
- Seamless authentication flow
- Preserves browser sessions

### ✅ Proper Web Authentication
- Uses Google's official sign-in button (required by Google)
- Single-click authentication
- No double popups
- Compliant with Google's web OAuth requirements

### ✅ Long-Term Backend Access
- Refresh tokens stored securely
- Backend can access Drive anytime
- No repeated user authentication needed

### ✅ Persistent Login
- User stays logged in indefinitely
- Only explicit logout ends session
- 30-day session validity (configurable)

## 📝 What Changed?

### Package Migration
```diff
- google_sign_in: ^7.2.0
- google_sign_in_web: ^1.1.0
+ google_sign_in_all_platforms: ^2.0.2
```

### Authentication Flow
```diff
- Separate authenticate() + authorizeScopes() calls → Double popup
+ Single signIn() call → One popup

- No refresh token management
+ Full refresh token support for backend

- Limited platform support
+ Windows, Linux, Web, Android, iOS all supported
```

### API Changes
```dart
// OLD (google_sign_in v7)
await GoogleSignIn.instance.initialize(...);
await GoogleSignIn.instance.authenticate(scopeHint: scopes);
await account.authorizationClient.authorizationForScopes(scopes);

// NEW (google_sign_in_all_platforms)
_googleSignIn = GoogleSignIn(params: GoogleSignInParams(...));
await _googleSignIn!.signIn(); // Single call!
```

## 🐛 Troubleshooting

### "Sign-in failed" on Windows
- **Check**: `GOOGLE_CLIENT_SECRET` in dart_defines.json
- **Required** for desktop platforms

### "Redirect URI mismatch"
- **Check**: Google Console has `http://localhost:8000`
- Port must match `redirectPort` in GoogleSignInParams

### "User not staying logged in"
- **Check**: StorageService is properly saving tokens
- **Check**: Session hasn't expired (30 days default)
- **Clear** storage and sign in again: `StorageService.clearAll()`

### Web: "UnimplementedError: Use the signInButton() widget"
- **Fixed**: Web now uses Google's official sign-in button
- This is a Google requirement for web OAuth
- See `WEB_AUTHENTICATION_FIX.md` for details

### Web popup blocked
- Enable popups for localhost in browser settings
- Google's official button reduces popup blocking

### Backend can't access Drive
- **Verify**: Drive scope included in sign-in request
- **Verify**: Refresh token sent to backend
- **Check**: Backend logs for token storage errors

## 📚 Additional Documentation

- **Full Migration Guide**: `GOOGLE_SIGN_IN_ALL_PLATFORMS_MIGRATION.md`
- **Original OAuth Setup**: `GOOGLE_OAUTH_SETUP.md`
- **Package Documentation**: https://pub.dev/packages/google_sign_in_all_platforms

## ✨ Benefits Summary

| Feature | Before | After |
|---------|--------|-------|
| Windows Support | ❌ | ✅ |
| Linux Support | ❌ | ✅ |
| Web Double Popup | ❌ | ✅ Fixed |
| Refresh Tokens | ❌ | ✅ |
| Backend Long-Term Access | ❌ | ✅ |
| Persistent Login | Partial | ✅ Full |
| Code Complexity | High | Low |

## 🎉 You're Ready!

The authentication system is now:
- ✅ Cross-platform (including Windows/Linux)
- ✅ User-friendly (single-click, no popups)
- ✅ Persistent (users stay logged in)
- ✅ Backend-friendly (long-term Drive access)

Just run the app and test the sign-in flow!

