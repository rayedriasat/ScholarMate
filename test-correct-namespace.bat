@echo off
REM Test RAG query with the CORRECT UUID where documents are actually stored

set GOOGLE_ID=111828646872592591995
set CORRECT_UUID=98c99792-d53f-4297-aba5-eca7bc0bf567
set BACKEND_URL=http://localhost:8000

echo ========================================
echo Testing with CORRECT UUID
echo ========================================
echo.
echo Your documents are indexed under UUID: %CORRECT_UUID%
echo But queries might be using a DIFFERENT UUID!
echo.
echo Let's test with the correct one...
echo.

echo Making test query...
curl -X POST "%BACKEND_URL%/api/ai/chat-rag" ^
  -H "Content-Type: application/json" ^
  -d "{\"question\": \"summarize\", \"user_id\": \"%CORRECT_UUID%\", \"selected_file_ids\": [], \"top_k\": 5}"

echo.
echo.
echo Check backend logs for:
echo   [NAMESPACE] Query resolved user_id ... to UUID ...
echo   [NAMESPACE] Querying Pinecone namespace: user_...
echo.
echo If it shows user_98c99792_d53f_4297_aba5_eca7bc0bf567, it should work!
echo.

pause
