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
} catch {
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
} catch {
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
    } catch {
        Write-Host "❌ Missing: $SecretName" -ForegroundColor Red
        $script:MissingSecrets = $true
    }
}

Check-Secret "SUPABASE_URL"
Check-Secret "SUPABASE_KEY"
Check-Secret "SUPABASE_SERVICE_KEY"
Check-Secret "GOOGLE_CLIENT_ID"
Check-Secret "GOOGLE_CLIENT_SECRET"
Check-Secret "PINECONE_API_KEY"
Check-Secret "GROQ_API_KEY"
Check-Secret "ENCRYPTION_KEY"

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

