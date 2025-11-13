# Android Network Fix - Metadata Not Loading

## Problem
Metadata sidebar works on web but not on Android.

## Root Cause
Android apps cannot access `localhost` or `127.0.0.1` because those refer to the Android device itself, not your development computer.

## Solution: Use Your Computer's Local IP Address

### Step 1: Find Your Computer's IP Address

**Windows:**
```bash
ipconfig
```
Look for "IPv4 Address" under your active network adapter (usually starts with 192.168.x.x or 10.0.x.x)

**macOS/Linux:**
```bash
ifconfig
```
or
```bash
ip addr show
```

Example IP: `192.168.1.100`

### Step 2: Update dart_defines.json

Edit `frontend/dart_defines.json`:

```json
{
  "API_BASE_URL": "http://192.168.1.100:8000"
}
```

Replace `192.168.1.100` with YOUR computer's actual IP address.

### Step 3: Restart the App

```bash
cd frontend
flutter run -d <your-android-device>
```

## Alternative: Use Android Emulator Port Forwarding

If using Android Emulator (not physical device):

```bash
adb reverse tcp:8000 tcp:8000
```

Then you can keep `API_BASE_URL` as `http://localhost:8000`

## Testing

1. Open a PDF in the Android app
2. Click the info icon (ⓘ)
3. Metadata should now load

## Common Issues

**"Connection refused"**
- Check firewall allows port 8000
- Verify backend is running
- Ensure phone and computer are on same WiFi network

**"Network unreachable"**
- Phone must be on same network as computer
- Check IP address is correct
- Try pinging the IP from another device

## For Production

For production builds, use a proper domain name or cloud-hosted backend URL.
