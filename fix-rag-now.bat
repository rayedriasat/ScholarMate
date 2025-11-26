@echo off
REM Quick fix for RAG - Clear mixed embeddings and re-index
REM Problem: You have embeddings from 3 different sources (old API, new API, local)
REM Solution: Clear everything and re-index with consistent local model

set USER_ID=111828646872592591995
set BACKEND_URL=http://localhost:8000

echo ========================================
echo RAG Quick Fix - Clear Mixed Embeddings
echo ========================================
echo.
echo Problem: Your embeddings are from mixed sources:
echo   - Old HuggingFace API (before Nov 26)
echo   - New HuggingFace API (404 errors)
echo   - Local model (fallback)
echo.
echo These are INCOMPATIBLE - queries can't find documents!
echo.
echo Solution: Clear ALL embeddings and re-index with local model
echo ========================================
echo.
echo User ID: %USER_ID%
echo Backend: %BACKEND_URL%
echo.
pause

echo Step 1: Checking backend health...
curl -s "%BACKEND_URL%/api/health" 2>nul | findstr "status"
if errorlevel 1 (
    echo ERROR: Backend not responding!
    echo Please start backend: cd backend ^& uv run python run.py
    pause
    exit /b 1
)
echo ✓ Backend is healthy!
echo.

echo Step 2: Clearing ALL old embeddings...
echo (This deletes your entire Pinecone namespace)
curl -X DELETE "%BACKEND_URL%/api/ingest/clear/%USER_ID%"
echo.
echo ✓ Namespace cleared!
echo.

echo Step 3: Verifying namespace is empty...
curl -s "%BACKEND_URL%/api/ingest/list/%USER_ID%" 2>nul
echo.
echo.

echo ========================================
echo Fix Complete!
echo ========================================
echo.
echo IMPORTANT: Now you MUST re-upload your PDFs:
echo.
echo 1. Open your app
echo 2. Go to your file list
echo 3. Re-upload ALL your PDF files
echo 4. Wait for indexing to complete (uses local model now)
echo 5. Try your AI chat query again
echo.
echo The local model is slower but consistent!
echo All embeddings will now be in the same vector space.
echo.

pause
