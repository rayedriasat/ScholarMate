@echo off
REM Diagnose namespace mismatch issue

set USER_ID=111828646872592591995
set BACKEND_URL=http://localhost:8000

echo ========================================
echo Namespace Mismatch Diagnosis
echo ========================================
echo.
echo Google User ID: %USER_ID%
echo.

echo Step 1: Check which UUID your documents are indexed under...
curl -s "%BACKEND_URL%/api/ingest/list/%USER_ID%" 2>nul > temp_jobs.json
type temp_jobs.json | findstr "user_id"
echo.

echo Step 2: Try a test query to see which namespace it queries...
echo (Check backend logs for "Queried namespace user_...")
echo.

echo Step 3: Check backend logs now...
echo Look for these lines:
echo   - "Resolved user_id ... to UUID ..."
echo   - "Queried namespace user_..."
echo   - "Added documents to namespace user_..."
echo.
echo If the UUIDs are DIFFERENT, that's your problem!
echo.

del temp_jobs.json 2>nul

pause
