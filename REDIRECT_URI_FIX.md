# Windows Redirect URI Fix

## The Error

When signing in on Windows, you see:

```
Error 400: redirect_uri_mismatch
```

## The Cause

Windows desktop OAuth uses a **different redirect URI** than web:

- **Web:** `http://localhost:8080/auth/callback`
- **Windows/Linux:** `http://localhost:3000` (no path, different port)
- **Backend:** `http://localhost:8000` (your backend API)

Your Google Cloud Console only has the web URI configured.

## The Fix

### Add Windows Redirect URI to Google Cloud Console

1. **Go to:** https://console.cloud.google.com/apis/credentials

2. **Find your OAuth 2.0 Client ID:**
   - Name: `Web client 1` (or similar)
   - Client ID: `325415234543-menqofjbigrju70tbi7oab4p5ath82lc.apps.googleusercontent.com`

3. **Click on it to edit**

4. **In "Authorized redirect URIs", add:**
   ```
   http://localhost:3000
   ```

5. **You should now have BOTH:**
   ```
   http://localhost:8080/auth/callback    (for web)
   http://localhost:3000                   (for Windows/Linux)
   ```

6. **Click "Save"**

7. **Wait 30 seconds** for changes to propagate

8. **Try signing in on Windows again** ✅

## Why This Is Needed

### Desktop OAuth Flow

Desktop apps (Windows/Linux) use a simplified OAuth flow:

1. App starts local web server on port **3000**
2. Opens browser to Google OAuth
3. User signs in
4. Google redirects to `http://localhost:3000` with auth code
5. App captures code and exchanges for tokens

### Port Configuration

The redirect port is configured in `auth_service.dart`:

```dart
_googleSignIn = GoogleSignIn(
  params: GoogleSignInParams(
    clientId: clientId,
    clientSecret: clientSecret,
    scopes: _scopes,
    redirectPort: 3000,  // ← Windows/Linux use this port (avoiding 8000 for backend)
    timeout: const Duration(minutes: 2),
  ),
);
```

## Platform-Specific Redirect URIs

| Platform | Redirect URI | Where Configured |
|----------|--------------|------------------|
| **Web** | `http://localhost:8080/auth/callback` | Flutter dev server default |
| **Windows** | `http://localhost:3000` | `auth_service.dart` line 80 |
| **Linux** | `http://localhost:3000` | `auth_service.dart` line 80 |
| **Backend API** | `http://localhost:8000` | Your FastAPI server |
| **Android** | `com.googleusercontent.apps.YOUR-ID:/oauth2redirect` | Auto-generated |
| **iOS** | `com.googleusercontent.apps.YOUR-ID:/oauth2redirect` | Auto-generated |

## Production Considerations

### For Deployed Web App

When deploying to production, add your production URL:
```
https://yourapp.com/auth/callback
https://www.yourapp.com/auth/callback
```

### For Desktop Distribution

Keep `http://localhost:3000` - it works for all users because:
- ✅ Each user's machine has its own localhost
- ✅ Port 3000 is used locally during OAuth flow
- ✅ No security concerns (localhost only)
- ✅ Port 3000 chosen to avoid conflict with backend (port 8000)

## Troubleshooting

### Still getting redirect_uri_mismatch after adding?

**Wait longer:** Google can take up to 5 minutes to propagate changes

**Check exact match:** 
- No trailing slash: `http://localhost:3000` ✅
- Not: `http://localhost:3000/` ❌

**Verify port:**
- Port 3000, not 8000 or 8080 ✅
- No path like `/auth/callback` ✅

### Want to use a different port?

Change `redirectPort` in `auth_service.dart`:

```dart
redirectPort: 8080,  // Change to your preferred port
```

Then add to Google Console:
```
http://localhost:8080
```

### Error on Linux too?

Same fix - add `http://localhost:8000` (Linux uses same port as Windows)

## Quick Reference

### Your Google Cloud Console Should Have:

**Application type:** Web application

**Authorized JavaScript origins:**
```
http://localhost
http://localhost:8080
```

**Authorized redirect URIs:**
```
http://localhost:8080/auth/callback    ← Web (Flutter dev server)
http://localhost:3000                   ← Windows/Linux desktop
```

### Test Commands

```bash
# Test web (port 8080)
flutter run -d chrome --dart-define-from-file=dart_defines.json

# Test Windows (port 8000)
flutter run -d windows --dart-define-from-file=dart_defines.json

# Test Android (uses bundle ID)
flutter run -d <device> --dart-define-from-file=dart_defines.json
```

## Summary

**Problem:** Windows OAuth uses `http://localhost:3000`, not configured in Google Console

**Solution:** Add `http://localhost:3000` to "Authorized redirect URIs"

**Time:** 2 minutes (30 seconds to add + 30-60 seconds to propagate)

**Result:** Windows authentication will work! ✅

---

**Quick Steps:**
1. Go to https://console.cloud.google.com/apis/credentials
2. Edit your OAuth 2.0 Client ID
3. Add `http://localhost:3000` to redirect URIs
4. Save and wait 30 seconds
5. Try Windows login again

