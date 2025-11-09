@echo off
setlocal enabledelayedexpansion
echo ========================================
echo   ScholarMate Frontend Launcher
echo ========================================
echo.

cd frontend

REM Check if dart_defines.json exists
if not exist "dart_defines.json" (
    echo ERROR: dart_defines.json not found!
    echo.
    echo Please create it from the template:
    echo   copy dart_defines.json.template dart_defines.json
    echo.
    echo Then edit dart_defines.json with your configuration.
    pause
    exit /b 1
)

REM Detect local IP address
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set LOCAL_IP=%%a
    goto :found
)
:found
set LOCAL_IP=%LOCAL_IP:~1%

echo Detected local IP: %LOCAL_IP%
echo.

REM Ask for backend connection method
echo Select backend connection method:
echo   1. Use localhost (http://localhost:8000)
echo   2. Use local IP (http://%LOCAL_IP%:8000)
echo   3. Custom IP address
echo.
set /p BACKEND_CHOICE="Enter choice (1/2/3), default=1: "
if "%BACKEND_CHOICE%"=="" set BACKEND_CHOICE=1

if "%BACKEND_CHOICE%"=="1" (
    set BACKEND_URL=http://localhost:8000
    set USE_LOCALHOST=1
) else if "%BACKEND_CHOICE%"=="2" (
    set BACKEND_URL=http://%LOCAL_IP%:8000
    set USE_LOCALHOST=0
) else if "%BACKEND_CHOICE%"=="3" (
    set /p CUSTOM_IP="Enter backend IP address: "
    set BACKEND_URL=http://!CUSTOM_IP!:8000
    set USE_LOCALHOST=0
) else (
    set BACKEND_URL=http://localhost:8000
    set USE_LOCALHOST=1
)

echo.
echo Backend URL: %BACKEND_URL%
echo.

REM Update dart_defines.json with the backend URL
echo Updating dart_defines.json with API_BASE_URL...

REM Read the JSON file and update API_BASE_URL
powershell -Command "$json = Get-Content 'dart_defines.json' | ConvertFrom-Json; $json.API_BASE_URL = '%BACKEND_URL%'; $json | ConvertTo-Json | Set-Content 'dart_defines.json'"

echo.
echo ========================================
echo Select platform:
echo   1. Android (USB debugging or emulator)
echo   2. Web (Edge browser)
echo   3. Windows Desktop
echo ========================================
echo.
set /p PLATFORM="Enter choice (1/2/3), default=2: "
if "%PLATFORM%"=="" set PLATFORM=2

REM Setup ADB port forwarding for Android with localhost
if "%PLATFORM%"=="1" (
    if "%USE_LOCALHOST%"=="1" (
        echo.
        echo Setting up ADB port forwarding for localhost...
        echo This allows Android to access backend at localhost:8000
        echo.
        adb reverse tcp:8000 tcp:8000
        if errorlevel 1 (
            echo WARNING: ADB port forwarding failed!
            echo Make sure:
            echo   1. USB debugging is enabled on your device
            echo   2. Device is connected via USB
            echo   3. ADB is in your PATH
            echo.
            echo You can continue, but the app may not connect to backend.
            pause
        ) else (
            echo ADB port forwarding successful!
            echo Android device can now access http://localhost:8000
            echo.
        )
    )
)

REM Set platform name
if "%PLATFORM%"=="1" (
    set PLATFORM_NAME=Android
) else if "%PLATFORM%"=="2" (
    set PLATFORM_NAME=Web ^(Edge^)
) else if "%PLATFORM%"=="3" (
    set PLATFORM_NAME=Windows Desktop
) else (
    set PLATFORM_NAME=Web ^(Edge^)
)

echo.
echo ========================================
echo Configuration:
echo   Backend: %BACKEND_URL%
echo   Platform: !PLATFORM_NAME!
echo ========================================
echo.
echo Starting Flutter app...
echo.

REM Run Flutter with dart-define-from-file
if "%PLATFORM%"=="1" (
    flutter run -d android --dart-define-from-file=dart_defines.json
) else if "%PLATFORM%"=="2" (
    flutter run -d edge --web-port=8080 --dart-define-from-file=dart_defines.json
) else if "%PLATFORM%"=="3" (
    flutter run -d windows --dart-define-from-file=dart_defines.json
) else (
    flutter run -d edge --web-port=8080 --dart-define-from-file=dart_defines.json
)

cd ..
