# Firebase Setup Automation Scripts Documentation

## Quick Start

Place these scripts in `scripts/` folder. Make executable:

```bash
chmod +x scripts/*.ps1  # Windows: Run PowerShell as Admin
```

---

## 📦 build-and-deploy.ps1

One-click builder for Web + Android with Firebase deployment.

### Usage

```powershell
# Build everything (web + android) and deploy
./scripts/build-and-deploy.ps1

# Build web only
./scripts/build-and-deploy.ps1 -target web

# Build android only
./scripts/build-and-deploy.ps1 -target android

# All with custom Firebase project
./scripts/build-and-deploy.ps1 -target all -firebaseProject my-project

# Skip version bump
./scripts/build-and-deploy.ps1 -skipVersionBump
```

### What It Does

1. ✅ Validates Flutter project setup
2. ✅ Runs `flutter pub get`
3. ✅ Builds web (`flutter build web --release`)
4. ✅ Builds Android (`flutter build apk --release`)
5. ✅ Deploys web to Firebase Hosting
6. ✅ Times the entire process
7. ✅ Shows colorized output

### Example Output

```
================================
PornoSocial Build & Deploy Tool
================================
Target: all | Firebase: pornosocial-c003d

▶ Phase 1: Validation
✓ Flutter project validated
✓ Dependencies verified

▶ Phase 2: Preparation
Current version: 1.0.0+1
✓ Dependencies installed

▶ Phase 3: Build
  Building Web...
  Built build/web/ (45.2MB)
  ✓ Web build complete

  Building Android APK...
  Built build/app/outputs/flutter-apk/app-release.apk (241.9MB)
  ✓ Android APK complete

▶ Phase 4: Deploy
  Deploying to Firebase Hosting...
  ✓ Live at: https://porno-social.com

================================
✅ Build complete in 15.43 minutes
================================
```

---

## 🚀 deploy-web.ps1

Quick deploy web to Firebase Hosting (skip build).

### Usage

```powershell
# Deploy web (assumes already built)
./scripts/deploy-web.ps1

# Deploy to specific Firebase project
./scripts/deploy-web.ps1 -firebaseProject my-project-id
```

### Prerequisites

Must have run build first:
```powershell
./scripts/build-and-deploy.ps1 -target web
```

### Output

```
🚀 Deploying Web to Firebase Hosting...
✅ Deployed! Visit: https://porno-social.com
```

---

## 📋 manage-version.ps1

Bump version, update CHANGELOG, create git tags/releases.

### Usage

```powershell
# Bump patch version (1.0.0 → 1.0.1)
./scripts/manage-version.ps1 -bump patch

# Bump minor version (1.0.0 → 1.1.0)
./scripts/manage-version.ps1 -bump minor

# Bump major version (1.0.0 → 2.0.0)
./scripts/manage-version.ps1 -bump major

# With changelog entry
./scripts/manage-version.ps1 -bump patch -changelog "Fixed authentication bug"

# Bump without git operations (local only)
./scripts/manage-version.ps1 -bump patch -skipGit
```

### What It Does

1. ✅ Parses current version from `pubspec.yaml`
2. ✅ Calculates new version
3. ✅ Updates `pubspec.yaml`
4. ✅ Updates/creates `CHANGELOG.md`
5. ✅ Git commits with message
6. ✅ Creates git tag (`v1.0.1`)
7. ✅ Shows push instructions

### Example

**Before:**
```yaml
version: 1.0.0+1
```

**Command:**
```powershell
./scripts/manage-version.ps1 -bump minor -changelog "Add shorts feature"
```

**After:**
```yaml
version: 1.1.0+2
```

**CHANGELOG.md:**
```markdown
## [1.1.0] - 2024-03-24
- Add shorts feature

## [1.0.0] - 2024-03-20
- Initial release
...
```

**Git:**
```bash
Commit: "Release v1.1.0"
Tag: v1.1.0
```

---

## 🎯 Typical Workflows

### Scenario 1: Deploy Updated Web + Android

```powershell
# Build and deploy everything
./scripts/build-and-deploy.ps1 -target all

# Result:
# - Web live at https://porno-social.com
# - APK ready at build/app/outputs/flutter-apk/app-release.apk
```

### Scenario 2: Release New Version

```powershell
# 1. Build everything
./scripts/build-and-deploy.ps1 -target all

# 2. Bump version with changelog
./scripts/manage-version.ps1 -bump minor -changelog "Add new feature X"

# 3. Push to GitHub
git push
git push --tags

# 4. Upload APK to Play Store manually
# (APK is ready at build/app/outputs/flutter-apk/app-release.apk)
```

### Scenario 3: Hotfix Deploy

```powershell
# 1. Make code changes locally
# 2. Test thoroughly
# 3. Deploy web immediately
./scripts/deploy-web.ps1

# 4. Version bump only (patch)
./scripts/manage-version.ps1 -bump patch -changelog "Hotfix: fix crash"

# 5. Tag and push
git push --tags
```

### Scenario 4: Morning Build Check

```powershell
# Ensure everything builds cleanly
./scripts/build-and-deploy.ps1 -target all -skipVersionBump

# If successful: ✅ Ready for day's work
# If fails: ❌ Fix build issues before starting
```

---

## 🔧 Troubleshooting Scripts

### Script won't run (Permission Denied)

**Windows (PowerShell):**
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or add to PowerShell profile
echo 'Set-ExecutionPolicy RemoteSigned' >> $PROFILE
```

**macOS/Linux (Bash):**
```bash
chmod +x scripts/*.sh
sudo ./scripts/build-and-deploy.sh
```

### Script fails on Flutter not found

```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Or use full path in script
/path/to/flutter/bin/flutter build web --release
```

### Firebase deploy fails

```powershell
# Verify Firebase CLI
firebase --version

# Login
firebase login

# List projects
firebase projects:list

# Test deployment
firebase deploy --only hosting --debug
```

### Git operations fail in script

```powershell
# Verify git is in PATH
git --version

# Configure git user
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

---

## 📊 Performance Tips

### Speed up builds:

```powershell
# Skip tree-shaking icons (faster, bigger APK)
flutter build apk --no-tree-shake-icons

# Use profile mode for testing
flutter build apk --profile

# Parallel pubsub operations
$jobs = @()
$jobs += (Start-Job -ScriptBlock { flutter pub get })
Wait-Job $jobs
```

### Reduce APK size:

```powershell
# Enable code shrinking (ProGuard/R8)
# In android/app/build.gradle.kts:
# minifyEnabled true
# shrinkResources true

flutter build apk --release --split-per-abi
```

---

## 🆘 Getting Help

**Issue:** Scripts don't work?  
**Solution:** Check the logs: `firebase deploy --debug`

**Issue:** Build fails?  
**Solution:** Run `flutter clean && flutter pub get`

**Issue:** Firebase auth issues?  
**Solution:** Verify in Firebase Console → Authentication

---

**Last Updated:** March 2026
