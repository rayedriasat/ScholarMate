# Complete Google Cloud Console Setup

## Your OAuth 2.0 Client Configuration

Based on your `dart_defines.json`, here's the **complete configuration** for Google Cloud Console:

### Client Information

**Client ID:** `325415234543-menqofjbigrju70tbi7oab4p5ath82lc.apps.googleusercontent.com`  
**Client Secret:** `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`

---

## Required Configuration

### 1. Application Type
```
Web application
```

### 2. Authorized JavaScript Origins

```
http://localhost
http://localhost:8080
```

### 3. Authorized Redirect URIs (COMPLETE LIST)

```
http://localhost:8080/auth/callback
http://localhost:3000
```

**Explanation:**
- `http://localhost:8080/auth/callback` → **Web** (Flutter dev server)
- `http://localhost:3000` → **Windows/Linux** desktop apps
- Port 3000 chosen to avoid conflict with backend API (port 8000)

---

## Step-by-Step Configuration

### Open Google Cloud Console

1. Go to: https://console.cloud.google.com/apis/credentials
2. Sign in with your Google account
3. Select your project

### Find Your OAuth Client

Look for:
- **Type:** OAuth 2.0 Client ID
- **Name:** Web client 1 (or similar)
- **Client ID:** `325415234543-...googleusercontent.com`

Click on it to edit.

### Configure Redirect URIs

In the **"Authorized redirect URIs"** section, you should have:

#### Currently (Web Only):
```
✅ http://localhost:8080/auth/callback
```

#### Add This (For Windows):
```
➕ http://localhost:3000
```

#### Final Configuration:
```
✅ http://localhost:8080/auth/callback    ← Web
✅ http://localhost:3000                   ← Windows/Linux
```

### Save Changes

1. Click **"Save"** button at the bottom
2. Wait for confirmation message
3. Wait **30-60 seconds** for changes to propagate globally

### Test

```bash
# Test Windows (should work now!)
cd E:\ScholarMate
run_windows.bat
```

---

## Platform Test Matrix

| Platform | Command | Redirect URI Used | Status |
|----------|---------|-------------------|--------|
| **Web** | `flutter run -d chrome` | `http://localhost:8080/auth/callback` | ✅ Working |
| **Windows** | `flutter run -d windows` | `http://localhost:3000` | ⚠️ **Add this** |
| **Android** | `flutter run -d <device>` | Auto (bundle ID) | ✅ Working |
| **Backend** | - | `http://localhost:8000` | 🔧 Your API server |

---

## Production Deployment

When deploying to production, add your production URLs:

### For Web App

```
https://yourapp.com/auth/callback
https://www.yourapp.com/auth/callback
```

### For Desktop Apps

Keep `http://localhost:3000` - it works for all distributed desktop apps because:
- Each user's machine has its own localhost
- OAuth happens locally on their machine
- No security concerns
- Port 3000 avoids conflicts with common dev servers (backend on 8000, web on 8080)

---

## Visual Summary

```
Google Cloud Console
  └── APIs & Services
      └── Credentials
          └── OAuth 2.0 Client IDs
              └── Your Client (325415234543-...)
                  └── Authorized redirect URIs
                      ├── http://localhost:8080/auth/callback  ✅ (Web)
                      └── http://localhost:3000                 ➕ (Add for Windows)
```

---

## Common Mistakes to Avoid

❌ **Don't do these:**
```
http://localhost:3000/           (trailing slash)
http://localhost:3000/callback   (wrong path)
http://localhost:8080            (wrong port - that's web)
http://localhost:8000            (wrong port - that's backend)
https://localhost:3000           (https instead of http)
```

✅ **Do this:**
```
http://localhost:3000
```

Exact match required - no trailing slash, no path, port 3000.

---

## After Configuration

### Test Windows Authentication

1. **Run app:**
   ```bash
   cd E:\ScholarMate
   run_windows.bat
   ```

2. **Click "Sign in with Google"**
   - Browser opens
   - Google login screen appears
   - Sign in with your account
   - Grant permissions
   - Redirects to `http://localhost:3000`
   - Returns to app
   - ✅ **Authenticated!**

3. **Verify:**
   - App shows home screen
   - Can access Google Drive
   - Can upload/download files
   - Sign out works

---

## Quick Checklist

Before testing Windows app:

- [ ] Opened Google Cloud Console
- [ ] Found OAuth 2.0 Client ID
- [ ] Added `http://localhost:3000` to redirect URIs
- [ ] Saved changes
- [ ] Waited 30-60 seconds
- [ ] Ready to test!

---

## Summary

**What to add:** `http://localhost:3000`  
**Where:** Google Cloud Console → Your OAuth Client → Authorized redirect URIs  
**Why:** Windows desktop uses port 3000 for OAuth callback (port 8000 is your backend)  
**When:** Before testing Windows authentication  
**Time:** 2 minutes  

After this, all platforms will work:
- ✅ Web
- ✅ Android  
- ✅ Windows

🎉 **Complete cross-platform authentication!**

