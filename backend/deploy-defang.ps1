# ScholarMate Backend - Defang Deployment Script (PowerShell)
# This script helps you deploy to Defang.io

$ErrorActionPreference = "Stop"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "ScholarMate Defang Deployment" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if Defang CLI is installed
try {
    $null = Get-Command defang -ErrorAction Stop
    Write-Host "✓ Defang CLI found" -ForegroundColor Green
}
catch {
    Write-Host "❌ Defang CLI not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install it first:"
    Write-Host "  iwr https://s.defang.io/install.ps1 -useb | iex"
    Write-Host ""
    exit 1
}

# Check if logged in
try {
    defang whoami 2>$null | Out-Null
    Write-Host "✓ Logged in to Defang" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "Not logged in to Defang. Logging in..."
    defang login
}

Write-Host ""

# Check if secrets are configured
Write-Host "Checking required environment variables..." -ForegroundColor Yellow
Write-Host ""

$MissingSecrets = $false

function Check-Secret {
    param($SecretName)
    try {
        defang config get $SecretName 2>$null | Out-Null
        Write-Host "✓ Found: $SecretName" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Missing: $SecretName" -ForegroundColor Red
        $script:MissingSecrets = $true
    }
}

Check-Secret "SUPABASE_URL"
Check-Secret "SUPABASE_KEY"
Check-Secret "SUPABASE_SERVICE_KEY"
Check-Secret "GOOGLE_CLIENT_ID"
Check-Secret "GOOGLE_CLIENT_SECRET"
Check-Secret "JWT_SECRET"
Check-Secret "PINECONE_API_KEY"
Check-Secret "HUGGINGFACEHUB_API_TOKEN"
Check-Secret "GROQ_API_KEY"
Check-Secret "ENCRYPTION_KEY"

# UNCOMMENT AND RUN ONCE TO SET SECRETS
# Write-Host "Setting secrets..." -ForegroundColor Yellow
# defang config set SUPABASE_URL="https://rqyzgfgdsedvohxyyqho.supabase.co"
# defang config set SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxeXpnZmdkc2Vkdm9oeHl5cWhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNTM5NzQsImV4cCI6MjA3NjYyOTk3NH0.mynXFTLHdzKg7Em2mfKXwNcRMPIsM9yv-7I9aWBkijE"
# defang config set SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxeXpnZmdkc2Vkdm9oeHl5cWhvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTA1Mzk3NCwiZXhwIjoyMDc2NjI5OTc0fQ.bblUhTIRO0fjEkpqtHfJtRwWSn5TRZtdLA3Ov9pLopE"
# defang config set GOOGLE_CLIENT_ID="325415234543-menqofjbigrju70tbi7oab4p5ath82lc.apps.googleusercontent.com"
# defang config set GOOGLE_CLIENT_SECRET="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"
# defang config set JWT_SECRET="F70qZMaz2MsSmLFEIXvTPdfgjwyHEBOP-gBO_dmIIEQ"
# defang config set PINECONE_API_KEY="pcsk_2in3nJ_EXqnUMyaUjGJfR6FpqLHXvqCgik5bcBENmrYrQ6bHVHXN8aKxUM5QYb9zxEVwJQ"
# defang config set HUGGINGFACEHUB_API_TOKEN="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"
# defang config set GROQ_API_KEY="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"
# defang config set ENCRYPTION_KEY="3Zqn5MjnRB0q-xsSdJiFdadb1A77Wmt8jMU6yBWLtKQ="
# defang config set OPENROUTER_API_KEY="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"

Write-Host ""

if ($MissingSecrets) {
    Write-Host "⚠️  Some required secrets are missing!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please set them using:"
    Write-Host "  defang config set SECRET_NAME secret_value"
    Write-Host ""
    Write-Host "See DEFANG_DEPLOYMENT.md for the complete list"
    Write-Host ""
    $response = Read-Host "Do you want to continue anyway? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        exit 1
    }
}

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Starting deployment..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Deploy
defang compose up

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Deployment complete!" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Get your service URL with:"
Write-Host "  defang compose ps"
Write-Host ""
Write-Host "View logs with:"
Write-Host "  defang compose logs backend -f"
Write-Host ""
Write-Host "Test health endpoint:"
Write-Host "  curl https://YOUR_URL.defang.dev/api/health"
Write-Host ""

