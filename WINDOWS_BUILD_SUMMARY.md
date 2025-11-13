# ✅ Windows Build Issue - SOLVED

## The Problem

When trying to build for Windows, you got this error:
```
NUGET.EXE not found.
Please install this executable, and run CMake again.
```

## The Cause

The `flutter_tts` package (used for text-to-speech in PDF viewer) requires **NuGet.exe** to download Windows C++ dependencies (`Microsoft.Windows.CppWinRT`).

This is a **one-time setup requirement** for Windows Flutter development.

## The Solution

### Quick Fix (2 minutes)

1. **Open PowerShell as Administrator:**
   - Press `Win + X`
   - Click "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Run this command:**
   ```powershell
   Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile "$env:LOCALAPPDATA\Microsoft\WindowsApps\nuget.exe"
   ```

3. **Close PowerShell and open a new terminal**

4. **Build the app:**
   ```bash
   cd E:\ScholarMate\frontend
   flutter clean
   flutter run -d windows --dart-define-from-file=dart_defines.json
   ```

### Or Use the Batch File

I've updated `run_windows.bat` to check for NuGet automatically:

```bash
# Just run this
E:\ScholarMate\run_windows.bat
```

It will:
- ✅ Check if NuGet is installed
- ⚠️ Show installation command if missing
- ✅ Run the app if everything is ready

## What Happens After Install

1. **First build** (2-3 minutes):
   - CMake downloads NuGet packages
   - Compiles C++ code
   - Creates Windows .exe

2. **Subsequent builds** (30-60 seconds):
   - Much faster (already compiled)
   - Only rebuilds changed files

## Expected Authentication Flow on Windows

Once the app is running:

1. **App launches** → Login screen appears
2. **Click "Sign in with Google"** → Default browser opens
3. **Browser shows Google login** → Sign in with your account
4. **Grant permissions** → Allow Drive access
5. **Browser redirects** → Shows `localhost:8000` briefly
6. **Back to app** → You're authenticated!
7. **Home screen loads** → Can access Google Drive

## Files Created/Modified

### Documentation
- ✅ `WINDOWS_NUGET_SETUP.md` - Detailed NuGet installation guide
- ✅ `WINDOWS_BUILD_SUMMARY.md` - This file (quick reference)
- ✅ `COOP_ERRORS_AND_WINDOWS_SETUP.md` - COOP warnings + Windows setup
- ✅ `install_nuget.bat` - Alternative installation script

### Scripts
- ✅ `run_windows.bat` - Updated with NuGet check

### Code (No Changes Needed)
- Your authentication code is already Windows-ready
- `dart_defines.json` has all required config
- `GOOGLE_CLIENT_SECRET` is present (required for desktop)

## Testing Checklist

After installing NuGet and running the app:

### ✅ Authentication
- [ ] App launches without errors
- [ ] Login screen shows
- [ ] Click sign-in → Browser opens
- [ ] Sign in succeeds
- [ ] App shows authenticated state

### ✅ Persistence
- [ ] Close app
- [ ] Reopen app
- [ ] Still signed in (no login prompt)

### ✅ Drive Access
- [ ] Can see files
- [ ] Can upload files
- [ ] Can download files

### ✅ Sign Out
- [ ] Sign out works
- [ ] Returns to login screen
- [ ] Reopen requires login

## Common Issues & Fixes

### "NUGET.EXE not found" - Still showing

**Cause:** NuGet not in PATH

**Fix:**
1. Verify installation: `where nuget.exe` in CMD
2. If not found, try installing to `C:\Windows\System32\`:
   ```powershell
   Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile "C:\Windows\System32\nuget.exe"
   ```
3. Close and reopen terminal

### Build fails with Visual Studio error

**Cause:** Visual Studio C++ tools not installed

**Fix:**
1. Install Visual Studio 2019 or 2022 Community (free)
2. Select "Desktop development with C++" workload
3. Restart and try again

### "Port 8000 already in use"

**Cause:** Another app using port 8000

**Fix:**
1. Close apps using port 8000
2. Or change port in `AuthService` (advanced)

## Why NuGet is Common for Windows Flutter

Many Flutter plugins require NuGet for Windows:
- ✅ `flutter_tts` - Text-to-speech (C++ Windows APIs)
- ✅ `win32` - Windows API access
- ✅ Various camera/media plugins
- ✅ Other native functionality

**This is normal Windows development** - just like Android needs Gradle and iOS needs CocoaPods.

## Summary

### What You Need to Do

1. **Install NuGet** (one command, 30 seconds)
2. **Run `flutter clean`** (clears old build)
3. **Run `run_windows.bat`** (builds and launches app)
4. **Test authentication** (browser-based OAuth)

### What's Already Done

- ✅ Windows platform files created
- ✅ Authentication configured for Windows
- ✅ Client secret present in config
- ✅ All documentation created
- ✅ Batch files ready

### Next Steps

```powershell
# 1. Install NuGet (PowerShell as Admin)
Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile "$env:LOCALAPPDATA\Microsoft\WindowsApps\nuget.exe"

# 2. Close PowerShell, open new terminal

# 3. Run the app
cd E:\ScholarMate
run_windows.bat
```

## Platform Status

| Platform | Status | Blocker | Action |
|----------|--------|---------|--------|
| ✅ Web | Working | COOP warnings (ignore) | `flutter run -d chrome` |
| ✅ Android | Working | None | `flutter run -d <device>` |
| ⚠️ **Windows** | **Ready** | **NuGet install needed** | **Install NuGet, then run** |

You're one command away from testing on all platforms! 🚀

---

**Quick Start:**
```powershell
# As Administrator
Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile "$env:LOCALAPPDATA\Microsoft\WindowsApps\nuget.exe"

# Then (new terminal)
cd E:\ScholarMate
run_windows.bat
```

