@echo off
REM Build and deploy script for Vercel (Windows)

echo.
echo 🔨 Building Flutter Web App
echo ============================
echo.

cd frontend
flutter build web --release --web-renderer canvaskit

if %errorlevel% neq 0 (
    echo.
    echo ❌ Build failed!
    cd ..
    exit /b 1
)

cd ..

echo.
echo ✅ Build successful!
echo.
echo 📦 Committing build folder...
echo.

git add frontend/build/web

if %errorlevel% neq 0 (
    echo.
    echo ❌ Git add failed!
    exit /b 1
)

git commit -m "Build web app for deployment - %date% %time%"

if %errorlevel% neq 0 (
    echo.
    echo ⚠️  Nothing to commit (no changes) or commit failed
)

echo.
echo 🚀 Ready to deploy!
echo.
echo Next steps:
echo 1. Push to git: git push origin main
echo 2. Deploy to Vercel: vercel --prod
echo.
echo Or run: git push ^&^& vercel --prod
echo.
