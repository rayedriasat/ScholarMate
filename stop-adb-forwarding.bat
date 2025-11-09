@echo off
echo ========================================
echo   Stop ADB Port Forwarding
echo ========================================
echo.

echo Removing ADB reverse port forwarding...
adb reverse --remove tcp:8000

if errorlevel 1 (
    echo.
    echo Failed to remove port forwarding.
    echo This is normal if no device is connected.
) else (
    echo.
    echo Port forwarding removed successfully!
)

echo.
pause
