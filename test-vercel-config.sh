#!/bin/bash

# Test script for Vercel configuration
# This script helps verify that the Vercel deployment is configured correctly

echo "🔍 Vercel Configuration Test"
echo "=============================="
echo ""

# Check if vercel.json exists
if [ -f "vercel.json" ]; then
    echo "✅ vercel.json found"
else
    echo "❌ vercel.json not found"
    exit 1
fi

# Check if api/config.js exists
if [ -f "api/config.js" ]; then
    echo "✅ api/config.js found"
else
    echo "❌ api/config.js not found"
    exit 1
fi

# Check if ConfigService has been updated
if grep -q "_detectVercelEnvironment" "frontend/lib/services/config_service.dart"; then
    echo "✅ ConfigService updated with Vercel detection"
else
    echo "❌ ConfigService not updated"
    exit 1
fi

# Check if http package is imported
if grep -q "import 'package:http/http.dart'" "frontend/lib/services/config_service.dart"; then
    echo "✅ HTTP package imported in ConfigService"
else
    echo "❌ HTTP package not imported"
    exit 1
fi

echo ""
echo "📋 Next Steps:"
echo "1. Set environment variables in Vercel dashboard"
echo "2. Update GOOGLE_REDIRECT_URI to your Vercel URL"
echo "3. Update API_BASE_URL to your backend URL"
echo "4. Add redirect URIs to Google Cloud Console"
echo "5. Deploy: vercel --prod"
echo ""
echo "📚 See VERCEL_DEPLOYMENT_CHECKLIST.md for complete guide"
