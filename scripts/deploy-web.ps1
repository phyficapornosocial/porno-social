# Quick Deploy to Firebase Hosting Only
# Usage: ./deploy-web.ps1

param(
    [Parameter(Mandatory=$false)]
    [string]$firebaseProject = "pornosocial-c003d"
)

function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }

Write-Info "🚀 Deploying Web to Firebase Hosting..."

if (-not (Test-Path "build/web")) {
    Write-Host "❌ build/web not found. Run './build-and-deploy.ps1 -target web' first" -ForegroundColor Red
    exit 1
}

firebase deploy --only hosting --project $firebaseProject

if ($LASTEXITCODE -eq 0) {
    Write-Success "✅ Deployed! Visit: https://porno-social.com"
} else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}
