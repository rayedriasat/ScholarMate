#!/bin/bash

# ScholarMate Backend - Defang Deployment Script
# This script helps you deploy to Defang.io

set -e  # Exit on error

echo "================================"
echo "ScholarMate Defang Deployment"
echo "================================"
echo ""

# Check if Defang CLI is installed
if ! command -v defang &> /dev/null; then
    echo "❌ Defang CLI not found!"
    echo ""
    echo "Please install it first:"
    echo "  macOS/Linux: curl -fsSL https://s.defang.io/install.sh | sh"
    echo "  Windows: iwr https://s.defang.io/install.ps1 -useb | iex"
    echo ""
    exit 1
fi

echo "✓ Defang CLI found"

# Check if logged in
if ! defang whoami &> /dev/null; then
    echo ""
    echo "Not logged in to Defang. Logging in..."
    defang login
fi

echo "✓ Logged in to Defang"
echo ""

# Check if secrets are configured
echo "Checking required environment variables..."
echo ""

MISSING_SECRETS=false

check_secret() {
    if ! defang config get "$1" &> /dev/null; then
        echo "❌ Missing: $1"
        MISSING_SECRETS=true
    else
        echo "✓ Found: $1"
    fi
}

check_secret "SUPABASE_URL"
check_secret "SUPABASE_KEY"
check_secret "SUPABASE_SERVICE_KEY"
check_secret "GOOGLE_CLIENT_ID"
check_secret "GOOGLE_CLIENT_SECRET"
check_secret "PINECONE_API_KEY"
check_secret "GROQ_API_KEY"
check_secret "ENCRYPTION_KEY"

echo ""

if [ "$MISSING_SECRETS" = true ]; then
    echo "⚠️  Some required secrets are missing!"
    echo ""
    echo "Please set them using:"
    echo "  defang config set SECRET_NAME secret_value"
    echo ""
    echo "See DEFANG_DEPLOYMENT.md for the complete list"
    echo ""
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "================================"
echo "Starting deployment..."
echo "================================"
echo ""

# Deploy
defang compose up

echo ""
echo "================================"
echo "Deployment complete!"
echo "================================"
echo ""
echo "Get your service URL with:"
echo "  defang compose ps"
echo ""
echo "View logs with:"
echo "  defang compose logs backend -f"
echo ""
echo "Test health endpoint:"
echo "  curl https://YOUR_URL.defang.dev/api/health"
echo ""

