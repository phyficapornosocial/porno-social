# Version Management & Release Script
# Bumps version, updates changelog, tags releases
# Usage: ./manage-version.ps1 -bump "patch|minor|major" [-changelog "What changed"]

param(
    [Parameter(Mandatory=$true, HelpMessage="Bump type: patch, minor, or major")]
    [ValidateSet("patch", "minor", "major")]
    [string]$bump,
    
    [Parameter(Mandatory=$false, HelpMessage="Changelog entry")]
    [string]$changelog,
    
    [Parameter(Mandatory=$false, HelpMessage="Skip git operations")]
    [switch]$skipGit
)

function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Error-Custom { Write-Host $args -ForegroundColor Red }

try {
    Write-Info "📋 Version Manager"
    
    # Parse current version
    $pubspec = Get-Content pubspec.yaml -Raw
    $versionMatch = $pubspec -match 'version:\s+(\d+)\.(\d+)\.(\d+)\+(\d+)'
    
    if (-not $versionMatch) {
        throw "Could not parse version from pubspec.yaml"
    }
    
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $build = [int]$matches[4]
    
    Write-Info "Current version: $major.$minor.$patch+$build"
    
    # Calculate new version
    switch ($bump) {
        "patch" { 
            $patch++
            $build++
            $versionType = "patch"
        }
        "minor" { 
            $minor++
            $patch = 0
            $build++
            $versionType = "minor"
        }
        "major" { 
            $major++
            $minor = 0
            $patch = 0
            $build++
            $versionType = "major"
        }
    }
    
    $newVersion = "$major.$minor.$patch+$build"
    Write-Success "New version: $newVersion ($versionType bump)"
    
    # Update pubspec.yaml
    $newPubspec = $pubspec -replace "version:\s+\d+\.\d+\.\d+\+\d+", "version: $newVersion"
    $newPubspec | Set-Content pubspec.yaml
    Write-Success "✓ pubspec.yaml updated"
    
    # Create/update CHANGELOG
    if ($changelog) {
        $changelogEntry = @"
## [$newVersion] - $(Get-Date -Format 'yyyy-MM-dd')
- $changelog

"@
        if (Test-Path "CHANGELOG.md") {
            $existing = Get-Content "CHANGELOG.md" -Raw
            $changelogEntry + $existing | Set-Content "CHANGELOG.md"
        } else {
            $changelogEntry | Set-Content "CHANGELOG.md"
        }
        Write-Success "✓ CHANGELOG.md updated"
    }
    
    # Git operations
    if (-not $skipGit) {
        Write-Info "Git operations..."
        & git add pubspec.yaml "CHANGELOG.md"
        & git commit -m "Release v$newVersion"
        & git tag "v$newVersion"
        Write-Success "✓ Git tagged: v$newVersion"
        Write-Info "Run 'git push --tags' to push to GitHub"
    }
    
    Write-Success "✅ Version bumped to $newVersion"
    
} catch {
    Write-Error-Custom "❌ Error: $_"
    exit 1
}
