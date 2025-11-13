@echo off
echo ===============================================
echo Installing NuGet for Windows Flutter Build
echo ===============================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as Administrator... Good!
) else (
    echo.
    echo ERROR: This script must be run as Administrator
    echo Please right-click and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

echo.
echo Downloading NuGet.exe...
powershell -Command "Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile '%LOCALAPPDATA%\Microsoft\WindowsApps\nuget.exe'"

if errorlevel 1 (
    echo.
    echo Failed to download NuGet
    echo Trying alternative location...
    powershell -Command "Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile 'C:\Windows\System32\nuget.exe'"
)

echo.
echo Verifying installation...
nuget help >nul 2>&1
if errorlevel 1 (
    echo.
    echo WARNING: NuGet may not be in PATH
    echo Please add %LOCALAPPDATA%\Microsoft\WindowsApps to your PATH
) else (
    echo.
    echo SUCCESS: NuGet installed successfully!
)

echo.
pause

