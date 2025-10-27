@echo off
echo Starting ScholarMate Backend...
echo.
echo Detecting local IP address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
    goto :found
)
:found
set IP=%IP:~1%
echo.
echo ========================================
echo Backend will be available at:
echo   Local:   http://localhost:8000
echo   Network: http://%IP%:8000
echo ========================================
echo.
echo Share the Network URL with your team!
echo.
cd backend
uv run python run.py
