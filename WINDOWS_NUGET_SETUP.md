# Windows Build Fix - NuGet Installation Required

## The Issue

When building for Windows, you encountered this error:

```
NUGET.EXE not found.
Please install this executable, and run CMake again.
```

This is because the `flutter_tts` package (used for text-to-speech) requires **NuGet** to download Windows C++ dependencies.

## Solution: Install NuGet

### Option 1: Quick Install (Run as Administrator)

1. **Open PowerShell as Administrator**
   - Press `Win + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Run this command:**
   ```powershell
   # Download NuGet to Windows Apps folder
   Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile "$env:LOCALAPPDATA\Microsoft\WindowsApps\nuget.exe"
   ```

3. **Verify installation:**
   ```powershell
   nuget help
   ```

   If this works, you're done!

### Option 2: Manual Download

1. **Download NuGet.exe:**
   - Go to: https://www.nuget.org/downloads
   - Download "nuget.exe" (latest version)

2. **Place it in your PATH:**
   - Move `nuget.exe` to: `C:\Windows\System32\`
   - Or: `%LOCALAPPDATA%\Microsoft\WindowsApps\`

3. **Verify:**
   ```cmd
   nuget help
   ```

### Option 3: Using Chocolatey

If you have Chocolatey installed:

```powershell
choco install nuget.commandline
```

### Option 4: Using Winget

If you have Winget (Windows 11 or Windows 10 with App Installer):

```powershell
winget install Microsoft.NuGet
```

## After Installing NuGet

1. **Close any open PowerShell/CMD windows**

2. **Clean Flutter build:**
   ```bash
   cd frontend
   flutter clean
   ```

3. **Try building again:**
   ```bash
   flutter run -d windows --dart-define-from-file=dart_defines.json
   ```

## Alternative: Disable TTS for Windows Testing

If you just want to test authentication and don't need text-to-speech:

1. **Comment out flutter_tts in pubspec.yaml:**
   ```yaml
   # flutter_tts: ^4.2.3  # Disabled for Windows testing
   ```

2. **Comment out TTS imports/usage:**
   - In `lib/main.dart`
   - In files that use TtsService

3. **Run:**
   ```bash
   flutter pub get
   flutter run -d windows
   ```

**Note:** This will break TTS features, but authentication will work fine.

## Why NuGet is Required

The `flutter_tts` package uses Windows C++ components that need to be downloaded via NuGet:
- `Microsoft.Windows.CppWinRT` - Windows Runtime C++ library
- Required for modern Windows API access
- Standard requirement for many Flutter Windows plugins

## Troubleshooting

### "NuGet still not found" after installation

**Fix PATH manually:**

1. Search for "Environment Variables" in Windows
2. Edit "System Variables" → "Path"
3. Add: `C:\Windows\System32\` (if not there)
4. Or: `%LOCALAPPDATA%\Microsoft\WindowsApps\`
5. Click OK and restart terminal

### "Permission denied" when installing

- Run PowerShell/CMD as **Administrator**
- Right-click → "Run as administrator"

### Build still fails after NuGet install

1. **Clean everything:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Delete build folder:**
   ```bash
   rmdir /s /q build
   ```

3. **Try again:**
   ```bash
   flutter run -d windows --dart-define-from-file=dart_defines.json
   ```

## Quick Start (TL;DR)

```powershell
# 1. Open PowerShell as Admin

# 2. Install NuGet
Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile "$env:LOCALAPPDATA\Microsoft\WindowsApps\nuget.exe"

# 3. Close and reopen terminal

# 4. Build app
cd E:\ScholarMate\frontend
flutter clean
flutter run -d windows --dart-define-from-file=dart_defines.json
```

## Summary

- ✅ **Install NuGet** (one-time setup)
- ✅ **Clean Flutter build**
- ✅ **Run Windows app**
- 🎉 **Test authentication!**

After NuGet is installed, Windows builds will work smoothly!

