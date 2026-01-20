# ScholarMate Frontend Setup Guide

## Quick Start

### 1. Create Configuration File

```bash
cd frontend
copy dart_defines.json.template dart_defines.json
```

Edit `dart_defines.json` with your actual values.

### 2. Run the App

**Option A: Use the launcher script (Recommended)**
```bash
start-frontend.bat
```
This interactive script will:
- Let you choose backend URL (localhost/local IP/custom)
- Select platform (Android/Web/Windows)
- Automatically set up ADB port forwarding for Android + localhost

**Option B: Quick run from frontend folder**
```bash
cd frontend
run_dev.bat          # Default device
run_dev.bat android  # Android
run_dev.bat chrome   # Chrome browser
run_dev.bat edge     # Edge browser
run_dev.bat windows  # Windows desktop
```

## Configuration System

ScholarMate uses **compile-time environment variables** via `--dart-define-from-file`.

### Why Not .env Files?

❌ `.env` files have issues:
- Asset bundling problems
- Platform inconsistencies
- Runtime loading errors
- Vercel deployment complications

✅ `dart_defines.json` benefits:
- Works on all platforms consistently
- Compile-time constants (better performance)
- No asset bundling needed
- Clean Vercel deployment

### Configuration Files

| File | Purpose | Commit? |
|------|---------|---------|
| `dart_defines.json` | Your local config | ❌ No (gitignored) |
| `dart_defines.json.template` | Template for team | ✅ Yes |

## Backend Connection Methods

### Method 1: Localhost (Recommended for Android)

**Pros:**
- Clean URLs
- No IP changes
- Faster connection

**Cons:**
- Requires USB connection for Android
- Needs ADB port forwarding

**Setup:**
```bash
# Automatic (via start-frontend.bat)
start-frontend.bat
# Select option 1 (localhost)
# Select option 1 (Android)

# Manual
adb reverse tcp:8000 tcp:8000
flutter run -d android --dart-define-from-file=dart_defines.json
```

### Method 2: Local IP (Recommended for Web/Multiple Devices)

**Pros:**
- Works wirelessly
- Multiple devices simultaneously
- No ADB needed

**Cons:**
- IP may change
- Firewall issues possible

**Setup:**
```bash
# Automatic (via start-frontend.bat)
start-frontend.bat
# Select option 2 (local IP)

# Manual - update dart_defines.json
{
  "API_BASE_URL": "http://192.168.x.x:8000"
}
```

### Method 3: Custom IP

For connecting to backend on another machine or network.

## Platform-Specific Notes

### Android

**Requirements:**
- USB debugging enabled
- Device connected via USB (for localhost method)
- ADB in PATH

**Localhost Setup:**
```bash
# Port forwarding (automatic via start-frontend.bat)
adb reverse tcp:8000 tcp:8000

# Verify
adb reverse --list

# Remove when done
adb reverse --remove tcp:8000
```

**Troubleshooting:**
See [ADB_PORT_FORWARDING.md](frontend/ADB_PORT_FORWARDING.md)

### Web

**Ports:**
- Frontend: `http://localhost:8080`
- Backend: `http://localhost:8000` (or your configured URL)

**Browsers:**
- Edge (default)
- Chrome

**Run:**
```bash
flutter run -d edge --web-port=8001 --dart-define-from-file=dart_defines.json
```

### Windows Desktop

**Run:**
```bash
flutter run -d windows --dart-define-from-file=dart_defines.json
```

## Building for Production

### Android APK

```bash
cd frontend
build_apk.bat

# Or manually
flutter build apk --dart-define-from-file=dart_defines.json
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Web

```bash
cd frontend
build_web.bat

# Or manually
flutter build web --dart-define-from-file=dart_defines.json
```

Output: `build/web/`

### Windows

```bash
flutter build windows --dart-define-from-file=dart_defines.json
```

Output: `build/windows/runner/Release/`

## VS Code Integration

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Dev)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define-from-file=dart_defines.json"
      ]
    },
    {
      "name": "Flutter (Android)",
      "request": "launch",
      "type": "dart",
      "args": [
        "-d",
        "android",
        "--dart-define-from-file=dart_defines.json"
      ]
    },
    {
      "name": "Flutter (Web)",
      "request": "launch",
      "type": "dart",
      "args": [
        "-d",
        "chrome",
        "--dart-define-from-file=dart_defines.json"
      ]
    }
  ]
}
```

## Vercel Deployment

For Vercel, set environment variables in the dashboard and use build command:

```bash
flutter build web \
  --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID \
  --dart-define=GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

Or use `vercel.json` to configure build settings.

## Troubleshooting

### "dart_defines.json not found"

```bash
cd frontend
copy dart_defines.json.template dart_defines.json
# Edit with your values
```

### "Failed to initialize app"

Check that all required fields in `dart_defines.json` are filled:
- `GOOGLE_CLIENT_ID`
- `API_BASE_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

### Android can't connect to backend

**If using localhost:**
1. Check ADB port forwarding: `adb reverse --list`
2. Re-run: `adb reverse tcp:8000 tcp:8000`

**If using local IP:**
1. Verify both devices on same network
2. Check firewall settings
3. Ping backend from Android: `adb shell ping 192.168.x.x`

### ADB not found

Add Android SDK platform-tools to PATH:
```
C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools
```

## Scripts Reference

| Script | Location | Purpose |
|--------|----------|---------|
| `start-frontend.bat` | Root | Interactive launcher with all options |
| `run_dev.bat` | frontend/ | Quick run with device selection |
| `build_apk.bat` | frontend/ | Build Android APK |
| `build_web.bat` | frontend/ | Build web app |
| `stop-adb-forwarding.bat` | Root | Remove ADB port forwarding |

## Additional Documentation

- [CONFIG_SETUP.md](frontend/CONFIG_SETUP.md) - Configuration details
- [ADB_PORT_FORWARDING.md](frontend/ADB_PORT_FORWARDING.md) - ADB guide
- [GOOGLE_OAUTH_SETUP.md](frontend/GOOGLE_OAUTH_SETUP.md) - OAuth setup
