@echo off
REM Test if namespace mismatch is the issue

set BACKEND_URL=http://localhost:8000

echo ========================================
echo Namespace Mismatch Test
echo ========================================
echo.

echo Test 1: Query with Google ID (current behavior)
echo ------------------------------------------------
curl -X POST "%BACKEND_URL%/api/ai/chat-rag" ^
  -H "Content-Type: application/json" ^
  -d "{\"question\": \"test\", \"user_id\": \"111828646872592591995\", \"selected_file_ids\": [], \"top_k\": 5}" ^
  2>nul | findstr "message"
echo.
echo Check logs - should show namespace: user_44b5d16b_fd69_4260_843d_df133c450832
echo Result: 0 results (WRONG namespace)
echo.
timeout /t 2 /nobreak >nul

echo Test 2: Query with CORRECT UUID (where docs actually are)
echo -----------------------------------------------------------
curl -X POST "%BACKEND_URL%/api/ai/chat-rag" ^
  -H "Content-Type: application/json" ^
  -d "{\"question\": \"test\", \"user_id\": \"98c99792-d53f-4297-aba5-eca7bc0bf567\", \"selected_file_ids\": [], \"top_k\": 5}" ^
  2>nul | findstr "message"
echo.
echo Check logs - should show namespace: user_98c99792_d53f_4297_aba5_eca7bc0bf567
echo Result: Should find documents! (CORRECT namespace)
echo.

echo ========================================
echo Conclusion
echo ========================================
echo.
echo If Test 2 returns results but Test 1 doesn't:
echo   → Namespace mismatch confirmed!
echo   → Fix: Use UUID 98c99792-d53f-4297-aba5-eca7bc0bf567 in frontend
echo.
echo If both return 0 results:
echo   → Different issue (embedding mismatch)
echo   → Fix: Run fix-rag-now.bat to clear and re-index
echo.

pause
