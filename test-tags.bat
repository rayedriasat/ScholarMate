@echo off
echo ========================================
echo Tag System Testing
echo ========================================
echo.

echo Step 1: Testing Backend Tag Service
echo ------------------------------------
cd backend
call uv run python test_tags.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Backend tests failed!
    echo Please check backend logs and Supabase connection.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Backend tests passed!
echo ========================================
echo.
echo Next steps:
echo 1. Start backend: cd backend ^&^& uv run python run.py
echo 2. Start frontend: cd frontend ^&^& flutter run -d chrome
echo 3. Follow TEST_TAGS_NOW.md for manual testing
echo.
pause
