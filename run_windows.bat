@echo off
echo ===============================================
echo ScholarMate - Windows Desktop App
echo ===============================================
echo.

REM Check for NuGet
where nuget.exe >nul 2>&1
if errorlevel 1 (
    echo WARNING: NuGet.exe not found in PATH
    echo.
    echo The flutter_tts package requires NuGet for Windows builds.
    echo.
    echo Quick Fix: Run this command as Administrator:
    echo   PowerShell -Command "Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile '$env:LOCALAPPDATA\Microsoft\WindowsApps\nuget.exe'"
    echo.
    echo Then close and reopen this terminal.
    echo.
    echo See WINDOWS_NUGET_SETUP.md for detailed instructions.
    echo.
    pause
    exit /b 1
)

echo NuGet found: OK
echo.
echo Starting application...
echo This may take a few minutes on first run.
echo.

cd frontend
flutter run -d windows --dart-define-from-file=dart_defines.json

if errorlevel 1 (
    echo.
    echo ===============================================
    echo Error: Failed to start application
    echo ===============================================
    echo.
    echo Possible causes:
    echo 1. Visual Studio not installed (requires C++ workload)
    echo 2. Windows desktop not enabled
    echo 3. Configuration error
    echo 4. NuGet packages failed to download
    echo.
    echo Please check the logs above for details.
    echo See WINDOWS_NUGET_SETUP.md for help.
    echo.
    pause
    exit /b 1
)

