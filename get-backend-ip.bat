@echo off
echo Detecting backend IP address...
echo.
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
    goto :found
)
:found
set IP=%IP:~1%
echo ========================================
echo Backend IP Address: %IP%
echo.
echo Share this URL with your team:
echo   http://%IP%:8000
echo ========================================
echo.
pause
