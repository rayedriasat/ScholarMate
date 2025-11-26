@echo off
REM Reindex all files after HuggingFace API endpoint fix
REM Usage: reindex-all-files.bat YOUR_USER_ID

if "%1"=="" (
    echo Usage: reindex-all-files.bat YOUR_USER_ID
    echo Example: reindex-all-files.bat 111828646872592591995
    exit /b 1
)

set USER_ID=%1
set BACKEND_URL=http://localhost:8000

echo ========================================
echo Reindexing All Files for User: %USER_ID%
echo ========================================
echo.

echo Step 1: Getting list of indexed files...
curl -s "%BACKEND_URL%/api/ingest/list/%USER_ID%" > temp_jobs.json

echo.
echo Step 2: Parsing file IDs...
REM Extract file_ids from JSON (requires PowerShell)
powershell -Command "$json = Get-Content temp_jobs.json | ConvertFrom-Json; $json.jobs | ForEach-Object { $_.file_id } | Select-Object -Unique" > temp_file_ids.txt

echo.
echo Step 3: Reindexing each file...
for /f "tokens=*" %%f in (temp_file_ids.txt) do (
    echo Reindexing file: %%f
    curl -X POST "%BACKEND_URL%/api/ingest/reindex/%%f" ^
         -H "Content-Type: application/json" ^
         -d "{\"user_id\": \"%USER_ID%\"}"
    echo.
)

echo.
echo ========================================
echo Reindexing jobs submitted!
echo ========================================
echo Check status at: %BACKEND_URL%/api/ingest/list/%USER_ID%
echo.

REM Cleanup
del temp_jobs.json temp_file_ids.txt 2>nul

pause
