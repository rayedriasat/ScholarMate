@echo off
echo ========================================
echo File Chat Fix - Test Script
echo ========================================
echo.

echo Step 1: Check if migration file exists
if exist "backend\migrations\011_fix_file_chat_rls.sql" (
    echo [OK] Migration file found
) else (
    echo [ERROR] Migration file not found
    exit /b 1
)
echo.

echo Step 2: Display migration SQL
echo ----------------------------------------
type backend\migrations\011_fix_file_chat_rls.sql
echo ----------------------------------------
echo.

echo Step 3: Instructions
echo.
echo TO APPLY THIS FIX:
echo.
echo 1. Copy the SQL above
echo 2. Go to: https://supabase.com/dashboard
echo 3. Select your project
echo 4. Go to: SQL Editor
echo 5. Paste the SQL
echo 6. Click "Run"
echo.
echo 7. Restart backend:
echo    cd backend
echo    uv run python run.py
echo.
echo 8. Restart frontend:
echo    cd frontend
echo    flutter run -d chrome
echo.
echo 9. Test file chat:
echo    - Open shared PDF
echo    - Click green chat bubble
echo    - Send message
echo    - Check console for errors
echo.
echo ========================================
pause
