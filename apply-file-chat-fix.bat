@echo off
echo ========================================
echo File Chat RLS Fix - Migration Script
echo ========================================
echo.

cd backend

echo Reading migration file...
type migrations\011_fix_file_chat_rls.sql
echo.
echo ========================================
echo.
echo INSTRUCTIONS:
echo 1. Copy the SQL above
echo 2. Go to Supabase Dashboard -^> SQL Editor
echo 3. Paste and click "Run"
echo.
echo OR use psql if you have direct database access:
echo psql YOUR_DATABASE_URL -f migrations/011_fix_file_chat_rls.sql
echo.
echo ========================================
pause
