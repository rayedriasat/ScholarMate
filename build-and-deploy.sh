#!/bin/bash

# Build and deploy script for Vercel (Linux/Mac)

echo ""
echo "🔨 Building Flutter Web App"
echo "============================"
echo ""

cd frontend
flutter build web --release --web-renderer canvaskit

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Build failed!"
    cd ..
    exit 1
fi

cd ..

echo ""
echo "✅ Build successful!"
echo ""
echo "📦 Committing build folder..."
echo ""

git add frontend/build/web

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Git add failed!"
    exit 1
fi

git commit -m "Build web app for deployment - $(date)"

if [ $? -ne 0 ]; then
    echo ""
    echo "⚠️  Nothing to commit (no changes) or commit failed"
fi

echo ""
echo "🚀 Ready to deploy!"
echo ""
echo "Next steps:"
echo "1. Push to git: git push origin main"
echo "2. Deploy to Vercel: vercel --prod"
echo ""
echo "Or run: git push && vercel --prod"
echo ""
