@echo off
echo ============================================
echo Tesseract OCR Installation Check
echo ============================================
echo.

echo Checking if Tesseract is in PATH...
where tesseract >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Tesseract found in PATH
    echo.
    echo Version:
    tesseract --version
    echo.
    echo [SUCCESS] Tesseract is properly installed!
    goto :test_backend
) else (
    echo [FAIL] Tesseract not found in PATH
    echo.
)

echo Checking common installation paths...
if exist "C:\Program Files\Tesseract-OCR\tesseract.exe" (
    echo [OK] Found at: C:\Program Files\Tesseract-OCR\tesseract.exe
    "C:\Program Files\Tesseract-OCR\tesseract.exe" --version
    echo.
    echo [INFO] Tesseract is installed but not in PATH
    echo [ACTION] Add to PATH or backend will auto-detect this location
    goto :test_backend
)

if exist "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe" (
    echo [OK] Found at: C:\Program Files (x86)\Tesseract-OCR\tesseract.exe
    "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe" --version
    echo.
    echo [INFO] Tesseract is installed but not in PATH
    echo [ACTION] Add to PATH or backend will auto-detect this location
    goto :test_backend
)

echo [FAIL] Tesseract not found in common locations
echo.
echo ============================================
echo Installation Required
echo ============================================
echo.
echo Please install Tesseract OCR:
echo 1. Visit: https://github.com/UB-Mannheim/tesseract/wiki
echo 2. Download the Windows installer
echo 3. Run the installer
echo 4. Run this script again to verify
echo.
echo Or use Chocolatey:
echo    choco install tesseract
echo.
echo See INSTALL_TESSERACT.md for detailed instructions
echo.
pause
exit /b 1

:test_backend
echo.
echo ============================================
echo Testing Backend OCR Service
echo ============================================
echo.
echo Checking if backend is running...
curl -s http://localhost:8000/api/ocr/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Backend is running
    echo.
    echo OCR Health Status:
    curl -s http://localhost:8000/api/ocr/health
    echo.
    echo.
    echo [SUCCESS] OCR service is ready!
) else (
    echo [INFO] Backend is not running
    echo.
    echo To start backend:
    echo    cd backend
    echo    uv run python run.py
    echo.
    echo Then test OCR:
    echo    cd backend
    echo    uv run python test_ocr.py
)

echo.
echo ============================================
echo Check Complete
echo ============================================
pause
