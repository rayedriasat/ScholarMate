# Restart Android App with New Configuration

## What Changed
Updated `API_BASE_URL` from `http://localhost:8000` to `http://192.168.0.121:8000`

This allows the Android app to connect to your backend server.

## Steps to Apply

### 1. Stop the Current App
Stop the Flutter app if it's running (Ctrl+C in terminal)

### 2. Restart with Hot Restart
```bash
cd frontend
flutter run -d <device-id>
```

Or if already running, press `R` (capital R) in the terminal for a full restart.

**Note:** Hot reload (lowercase `r`) won't pick up the config change. You need a full restart (capital `R`).

### 3. Test the Metadata Sidebar
1. Open any PDF
2. Click the info icon (ⓘ)
3. Metadata should now load

## Verify Backend is Accessible

From your Android device's browser, try opening:
```
http://192.168.0.121:8000/api/metadata/health
```

Should return: `{"status":"ok","service":"metadata"}`

## Troubleshooting

**Still not working?**
1. Ensure phone and computer are on the same WiFi network
2. Check Windows Firewall allows port 8000
3. Verify backend is running: `cd backend && uv run python run.py`

**To allow port 8000 through Windows Firewall:**
```powershell
netsh advfirewall firewall add rule name="Backend API" dir=in action=allow protocol=TCP localport=8000
```

## For Web Development
If you want to switch back to web development, change the URL back to:
```json
"API_BASE_URL": "http://localhost:8000"
```
