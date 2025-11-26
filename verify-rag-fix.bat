@echo off
REM Verify RAG fix is working

set USER_ID=111828646872592591995
set BACKEND_URL=http://localhost:8000

echo ========================================
echo RAG Fix Verification
echo ========================================
echo.

echo Checking backend status...
curl -s "%BACKEND_URL%/api/health" 2>nul | findstr "status"
echo.

echo Checking your namespace stats...
curl -s "%BACKEND_URL%/api/ingest/list/%USER_ID%" 2>nul
echo.
echo.

echo ========================================
echo What to look for:
echo ========================================
echo.
echo If "total": 0 or very few jobs:
echo   → You need to re-upload your PDFs
echo.
echo If jobs show "completed" status:
echo   → Good! Try AI chat now
echo.
echo If jobs show "failed" status:
echo   → Check backend logs for errors
echo.
echo If AI chat still returns no results:
echo   → Run fix-rag-now.bat to clear and start fresh
echo.

pause
