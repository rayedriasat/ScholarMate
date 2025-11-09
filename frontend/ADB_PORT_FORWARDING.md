# ADB Port Forwarding for Android Development

## What is ADB Port Forwarding?

ADB (Android Debug Bridge) port forwarding allows your Android device to access services running on your development machine's localhost.

## Why Do We Need It?

When your backend runs on `http://localhost:8000` on your PC, your Android device cannot access it directly because:
- Android device has its own "localhost" (127.0.0.1)
- Your PC's localhost is not accessible from the device

**Solution:** ADB reverse port forwarding maps the device's localhost:8000 to your PC's localhost:8000.

## How It Works

```
┌─────────────────┐         ┌──────────────────┐
│  Android Device │         │   Your PC        │
│                 │   USB   │                  │
│  localhost:8000 │◄────────┤  localhost:8000  │
│  (Flutter App)  │  ADB    │  (Backend API)   │
└─────────────────┘         └──────────────────┘
```

## Automatic Setup

The `start-frontend.bat` script automatically sets up port forwarding when you:
1. Select Android as platform
2. Choose localhost as backend URL

## Manual Setup

If you need to set it up manually:

```bash
# Forward port 8000
adb reverse tcp:8000 tcp:8000

# Verify it's working
adb reverse --list

# Remove forwarding when done
adb reverse --remove tcp:8000

# Remove all forwarding
adb reverse --remove-all
```

## Troubleshooting

### "adb: command not found"

**Solution:** Add Android SDK platform-tools to your PATH:
1. Find your Android SDK location (usually `C:\Users\YourName\AppData\Local\Android\Sdk`)
2. Add `platform-tools` folder to PATH
3. Restart your terminal

### "error: no devices/emulators found"

**Solution:**
1. Enable USB debugging on your Android device
2. Connect device via USB
3. Accept the "Allow USB debugging" prompt on your device
4. Run `adb devices` to verify connection

### "error: device unauthorized"

**Solution:**
1. Disconnect and reconnect USB cable
2. Check your device for authorization prompt
3. Select "Always allow from this computer"
4. Run `adb devices` again

### Port forwarding not working

**Solution:**
1. Remove existing forwarding: `adb reverse --remove-all`
2. Restart ADB server: `adb kill-server` then `adb start-server`
3. Set up forwarding again: `adb reverse tcp:8000 tcp:8000`

## Alternative: Use Local IP Instead

If ADB port forwarding doesn't work, you can use your PC's local IP address:

1. In `start-frontend.bat`, select option 2 (Use local IP)
2. Make sure your PC and Android device are on the same WiFi network
3. Backend will be accessible at `http://192.168.x.x:8000`

## When to Use Each Method

| Method | Use When | Pros | Cons |
|--------|----------|------|------|
| **localhost + ADB** | USB debugging | Clean URLs, no IP changes | Requires USB connection |
| **Local IP** | WiFi development | Wireless, works with multiple devices | IP may change, firewall issues |

## Best Practice

For development:
1. Use **localhost + ADB** for primary testing (faster, more reliable)
2. Use **Local IP** for testing on multiple devices simultaneously
3. Always stop port forwarding when done to avoid conflicts

## Scripts

- `start-frontend.bat` - Automatically sets up port forwarding
- `stop-adb-forwarding.bat` - Removes port forwarding
