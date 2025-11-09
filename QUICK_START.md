# ScholarMate Quick Start

## First Time Setup

```bash
# 1. Create config file
cd frontend
copy dart_defines.json.template dart_defines.json

# 2. Edit dart_defines.json with your values
notepad dart_defines.json

# 3. Install dependencies
flutter pub get

# 4. Run the app
cd ..
start-frontend.bat
```

## Daily Development

### Start Backend
```bash
cd backend
uv run python run.py
```

### Start Frontend

**Option 1: Interactive Launcher (Recommended)**
```bash
start-frontend.bat
```
Choose your backend URL and platform.

**Option 2: Quick Commands**
```bash
cd frontend

# Android with localhost (most common)
quick-android-localhost.bat

# Or specify device
run_dev.bat android
run_dev.bat chrome
run_dev.bat edge
run_dev.bat windows
```

## Common Scenarios

### Android Development with Localhost Backend

```bash
# Terminal 1: Start backend
cd backend
uv run python run.py

# Terminal 2: Start frontend
start-frontend.bat
# Select: 1 (localhost) → 1 (Android)
```

The script automatically sets up ADB port forwarding!

### Web Development

```bash
# Terminal 1: Start backend
cd backend
uv run python run.py

# Terminal 2: Start frontend
cd frontend
run_dev.bat edge
```

Open: http://localhost:8080

### Multiple Devices (WiFi)

```bash
# Terminal 1: Start backend
cd backend
uv run python run.py

# Terminal 2: Start frontend
start-frontend.bat
# Select: 2 (local IP) → 1 (Android)
```

## Building

```bash
cd frontend

# Android APK
build_apk.bat

# Web
build_web.bat

# Windows
flutter build windows --dart-define-from-file=dart_defines.json
```

## Troubleshooting

### Backend Connection Failed

**Android + Localhost:**
```bash
# Check ADB port forwarding
adb reverse --list

# Re-setup if needed
adb reverse tcp:8000 tcp:8000
```

**Web/WiFi:**
- Verify backend is running: http://localhost:8000/docs
- Check firewall settings
- Ensure same network

### Configuration Issues

```bash
# Verify config file exists
cd frontend
dir dart_defines.json

# Check values
type dart_defines.json
```

### ADB Issues

```bash
# Check device connection
adb devices

# Restart ADB
adb kill-server
adb start-server

# Setup port forwarding
adb reverse tcp:8000 tcp:8000
```

## Project Structure

```
ScholarMate/
├── backend/              # FastAPI backend
│   ├── app/
│   └── run.py
├── frontend/             # Flutter frontend
│   ├── lib/
│   ├── dart_defines.json          # Your config (gitignored)
│   ├── dart_defines.json.template # Template
│   ├── run_dev.bat               # Quick run
│   └── quick-android-localhost.bat
├── start-frontend.bat    # Interactive launcher
└── stop-adb-forwarding.bat
```

## Key URLs

- **Frontend (Web):** http://localhost:8080
- **Backend API:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

## Environment Variables

Edit `frontend/dart_defines.json`:

```json
{
  "GOOGLE_CLIENT_ID": "your-client-id",
  "API_BASE_URL": "http://localhost:8000",
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key"
}
```

## Documentation

- [FRONTEND_SETUP.md](FRONTEND_SETUP.md) - Complete frontend guide
- [frontend/CONFIG_SETUP.md](frontend/CONFIG_SETUP.md) - Configuration
- [frontend/ADB_PORT_FORWARDING.md](frontend/ADB_PORT_FORWARDING.md) - ADB guide
- [MIGRATION_TO_DART_DEFINES.md](MIGRATION_TO_DART_DEFINES.md) - Migration notes

## Need Help?

1. Check error messages in terminal
2. Review documentation above
3. Verify configuration in `dart_defines.json`
4. Check backend is running at http://localhost:8000/docs
