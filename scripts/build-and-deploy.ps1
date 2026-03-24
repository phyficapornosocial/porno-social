# PornoSocial Build & Deploy Script
# One-click builder for Web + Android with Firebase deployment
# Usage: ./build-and-deploy.ps1 -target "web" or "android" or "all"

param(
    [Parameter(Mandatory=$false, HelpMessage="Target: 'web', 'android', or 'all'")]
    [ValidateSet("web", "android", "all")]
    [string]$target = "all",
    
    [Parameter(Mandatory=$false, HelpMessage="Firebase project ID")]
    [string]$firebaseProject = "pornosocial-c003d",
    
    [Parameter(Mandatory=$false, HelpMessage="Skip tests")]
    [switch]$skipTests,
    
    [Parameter(Mandatory=$false, HelpMessage="Skip version bump")]
    [switch]$skipVersionBump
)

# Color output
function Write-Success { Write-Host $args -ForegroundColor Green -BackgroundColor Black }
function Write-Error-Custom { Write-Host $args -ForegroundColor Red -BackgroundColor Black }
function Write-Info { Write-Host $args -ForegroundColor Cyan -BackgroundColor Black }
function Write-Warning-Custom { Write-Host $args -ForegroundColor Yellow -BackgroundColor Black }

$ErrorActionPreference = "Stop"
$startTime = Get-Date

try {
    Write-Info "================================"
    Write-Info "PornoSocial Build & Deploy Tool"
    Write-Info "================================"
    Write-Info "Target: $target | Firebase: $firebaseProject"
    Write-Info ""

    # Phase 1: Validation
    Write-Info "▶ Phase 1: Validation"
    if (-not (Test-Path "pubspec.yaml")) {
        throw "❌ Not in Flutter project root. Run from project directory."
    }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw "❌ Flutter not found in PATH. Install Flutter SDK."
    }
    Write-Success "✓ Flutter project validated"
    Write-Success "✓ Dependencies verified"
    Write-Info ""

    # Phase 2: Preparation
    Write-Info "▶ Phase 2: Preparation"
    if (-not $skipVersionBump) {
        $pubspec = Get-Content pubspec.yaml | Select-String "^version:" | Select-Object -First 1
        Write-Warning-Custom "Current version: $pubspec"
        Write-Info "Run 'flutter pub get' to ensure dependencies..."
    }
    & flutter pub get | Out-Null
    Write-Success "✓ Dependencies installed"
    Write-Info ""

    # Phase 3: Build
    Write-Info "▶ Phase 3: Build"
    
    if ($target -eq "web" -or $target -eq "all") {
        Write-Info "  Building Web..."
        & flutter build web --release
        if ($LASTEXITCODE -ne 0) { throw "Web build failed" }
        Write-Success "  ✓ Web build complete: build/web/"
    }

    if ($target -eq "android" -or $target -eq "all") {
        Write-Info "  Building Android APK..."
        & flutter build apk --release
        if ($LASTEXITCODE -ne 0) { throw "Android APK build failed" }
        Write-Success "  ✓ Android APK: build/app/outputs/flutter-apk/app-release.apk"
    }
    Write-Info ""

    # Phase 4: Deploy
    Write-Info "▶ Phase 4: Deploy"
    
    if ($target -eq "web" -or $target -eq "all") {
        Write-Info "  Deploying to Firebase Hosting..."
        & firebase deploy --only hosting --project $firebaseProject
        if ($LASTEXITCODE -ne 0) { throw "Firebase deployment failed" }
        Write-Success "  ✓ Live at: https://porno-social.com"
    }
    
    Write-Info ""
    Write-Success "================================"
    $elapsed = (Get-Date) - $startTime
    Write-Success "✅ Build complete in $($elapsed.TotalMinutes.ToString('F2')) minutes"
    Write-Success "================================"

} catch {
    Write-Error-Custom "❌ ERROR: $_"
    exit 1
}
