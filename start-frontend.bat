@echo off
echo Starting ScholarMate Frontend...
echo.

REM Detect local IP address
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set LOCAL_IP=%%a
    goto :found
)
:found
set LOCAL_IP=%LOCAL_IP:~1%

REM Prompt user for backend IP (default to local IP)
echo.
echo Detected local IP: %LOCAL_IP%
echo.
set /p BACKEND_IP="Enter backend IP address (press Enter for %LOCAL_IP%): "
if "%BACKEND_IP%"=="" set BACKEND_IP=%LOCAL_IP%

REM Update .env file with the backend URL
echo.
echo Updating .env with API_BASE_URL=http://%BACKEND_IP%:8000
cd frontend

REM Create a temporary file with updated content
(
    for /f "usebackq delims=" %%a in (".env") do (
        echo %%a | findstr /b /c:"API_BASE_URL=" >nul
        if errorlevel 1 (
            echo %%a
        ) else (
            echo API_BASE_URL=http://%BACKEND_IP%:8000
        )
    )
) > .env.tmp

REM Replace original file
move /y .env.tmp .env >nul

echo.
echo ========================================
echo Frontend will connect to:
echo   http://%BACKEND_IP%:8000
echo ========================================
echo.

REM Ask which platform to run
echo Select platform:
echo   1. Android ^(requires USB debugging or emulator^)
echo   2. Web ^(Edge browser^)
echo   3. Windows Desktop
echo.
set /p PLATFORM="Enter choice 1/2/3, default=2: "
if "%PLATFORM%"=="" set PLATFORM=2

if "%PLATFORM%"=="1" (
    echo Starting on Android...
    flutter run
) else if "%PLATFORM%"=="2" (
    echo Starting on Web...
    flutter run -d edge --web-port=8080
) else if "%PLATFORM%"=="3" (
    echo Starting on Windows...
    flutter run -d windows
) else (
    echo Invalid choice, starting on Web...
    flutter run -d edge --web-port=8080
)

cd ..
