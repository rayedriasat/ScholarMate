@echo off
REM Quick launch: Android with localhost backend
REM This is the most common development setup

echo ========================================
echo   Quick Launch: Android + Localhost
echo ========================================
echo.

if not exist "dart_defines.json" (
    echo ERROR: dart_defines.json not found!
    echo Please create it: copy dart_defines.json.template dart_defines.json
    pause
    exit /b 1
)

echo Updating backend URL to localhost...
powershell -Command "$json = Get-Content 'dart_defines.json' | ConvertFrom-Json; $json.API_BASE_URL = 'http://localhost:8000'; $json | ConvertTo-Json | Set-Content 'dart_defines.json'"

echo Setting up ADB port forwarding...
adb reverse tcp:8000 tcp:8000

if errorlevel 1 (
    echo.
    echo WARNING: ADB port forwarding failed!
    echo Make sure USB debugging is enabled and device is connected.
    echo.
    pause
)

echo.
echo Launching app on Android...
flutter run -d android --dart-define-from-file=dart_defines.json
