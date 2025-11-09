@echo off
REM Test script for Vercel configuration (Windows)
REM This script helps verify that the Vercel deployment is configured correctly

echo.
echo 🔍 Vercel Configuration Test
echo ==============================
echo.

REM Check if vercel.json exists
if exist "vercel.json" (
    echo ✅ vercel.json found
) else (
    echo ❌ vercel.json not found
    exit /b 1
)

REM Check if api/config.js exists
if exist "api\config.js" (
    echo ✅ api/config.js found
) else (
    echo ❌ api/config.js not found
    exit /b 1
)

REM Check if ConfigService has been updated
findstr /C:"_detectVercelEnvironment" "frontend\lib\services\config_service.dart" >nul
if %errorlevel% equ 0 (
    echo ✅ ConfigService updated with Vercel detection
) else (
    echo ❌ ConfigService not updated
    exit /b 1
)

REM Check if http package is imported
findstr /C:"import 'package:http/http.dart'" "frontend\lib\services\config_service.dart" >nul
if %errorlevel% equ 0 (
    echo ✅ HTTP package imported in ConfigService
) else (
    echo ❌ HTTP package not imported
    exit /b 1
)

echo.
echo 📋 Next Steps:
echo 1. Set environment variables in Vercel dashboard
echo 2. Update GOOGLE_REDIRECT_URI to your Vercel URL
echo 3. Update API_BASE_URL to your backend URL
echo 4. Add redirect URIs to Google Cloud Console
echo 5. Deploy: vercel --prod
echo.
echo 📚 See VERCEL_DEPLOYMENT_CHECKLIST.md for complete guide
echo.
