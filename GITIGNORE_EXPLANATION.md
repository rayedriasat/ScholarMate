# .gitignore Configuration for Vercel Deployment

## Overview

This project uses a special `.gitignore` configuration to support deploying prebuilt Flutter web files to Vercel while excluding other build artifacts.

## Configuration

### Root `.gitignore`

```gitignore
# Build folders (exclude all build artifacts EXCEPT frontend/build/web for Vercel)
build/
!frontend/build/
frontend/build/*
!frontend/build/web/
```

**How it works:**
1. `build/` - Ignores all build folders everywhere
2. `!frontend/build/` - Un-ignores the frontend/build directory itself
3. `frontend/build/*` - Ignores everything inside frontend/build
4. `!frontend/build/web/` - Un-ignores the web folder specifically

### Frontend `.gitignore`

```gitignore
# Build folders - exclude all except web (needed for Vercel)
/build/android/
/build/ios/
/build/linux/
/build/macos/
/build/windows/
# /build/web/ is intentionally NOT ignored - needed for Vercel deployment
```

**How it works:**
- Explicitly ignores platform-specific build folders
- Leaves `/build/web/` unignored for Vercel deployment

## What Gets Committed

### ✅ Included in Git

- `frontend/build/web/` - All web build files
  - `index.html`
  - `main.dart.js`
  - `flutter.js`
  - `canvaskit/`
  - `assets/`
  - All other web build artifacts

### ❌ Excluded from Git

- `build/` - Root build folder
- `frontend/build/android/` - Android builds
- `frontend/build/ios/` - iOS builds
- `frontend/build/linux/` - Linux builds
- `frontend/build/macos/` - macOS builds
- `frontend/build/windows/` - Windows builds
- `backend/` build artifacts
- All other build folders

## Verification

### Check if a file is ignored

```bash
# Should show nothing (file is tracked)
git check-ignore frontend/build/web/index.html

# Should show the file can be added
git add -n frontend/build/web/index.html
```

### Check status of web build folder

```bash
# Should show ?? (untracked) or M (modified) for web files
git status --short frontend/build/web/
```

### List ignored files

```bash
# Should NOT include frontend/build/web/ files
git ls-files --others --ignored --exclude-standard frontend/build/
```

## Common Issues

### Issue: Web files are being ignored

**Symptom:** `git status` doesn't show `frontend/build/web/` files

**Solution:**
1. Check both `.gitignore` files (root and `frontend/.gitignore`)
2. Ensure patterns match exactly as shown above
3. Clear git cache: `git rm -r --cached frontend/build/web/`
4. Re-add: `git add frontend/build/web/`

### Issue: Platform builds are being tracked

**Symptom:** `git status` shows `frontend/build/android/` or other platforms

**Solution:**
1. Verify `frontend/.gitignore` has platform-specific ignores
2. Remove from tracking: `git rm -r --cached frontend/build/android/`
3. Commit: `git commit -m "Remove platform builds from tracking"`

### Issue: Root build folder is tracked

**Symptom:** `git status` shows `build/` at project root

**Solution:**
1. Verify root `.gitignore` has `build/` pattern
2. Remove from tracking: `git rm -r --cached build/`
3. Commit: `git commit -m "Remove root build folder"`

## Why This Approach?

### Advantages

✅ **Fast deployments** - No build step on Vercel (~30 seconds vs 5+ minutes)
✅ **Consistent builds** - Same environment every time
✅ **Easy debugging** - See exactly what's deployed
✅ **No CI/CD complexity** - Simple git push workflow
✅ **Lower costs** - Less build time on Vercel

### Disadvantages

⚠️ **Larger repository** - Web builds are ~10-50 MB
⚠️ **Manual builds** - Must rebuild locally before deploying
⚠️ **Merge conflicts** - Build files can conflict in PRs

### Alternatives Considered

1. **Build on Vercel** - Requires Flutter in CI, slower, more complex
2. **Git LFS** - Adds complexity, not necessary for this size
3. **Separate repo** - Harder to maintain, sync issues

## Best Practices

### ✅ Do

- Commit web builds with descriptive messages
- Build before every deployment
- Keep builds up to date with code changes
- Use `.gitattributes` for binary files if needed

### ❌ Don't

- Don't commit platform-specific builds (Android, iOS, etc.)
- Don't manually edit files in `build/web/`
- Don't forget to rebuild after code changes
- Don't commit debug builds (always use `--release`)

## Testing Your Configuration

Run this script to verify your `.gitignore` is configured correctly:

```bash
# Windows
test-vercel-config.bat

# Linux/Mac
./test-vercel-config.sh
```

Or manually test:

```bash
# 1. Build the web app
cd frontend
flutter build web --release
cd ..

# 2. Check git status (should show web files)
git status frontend/build/web/

# 3. Try to add files (should work)
git add -n frontend/build/web/index.html

# 4. Verify other builds are ignored
git status frontend/build/android/  # Should show nothing
```

## Maintenance

### When updating Flutter

After updating Flutter SDK, rebuild and commit:

```bash
cd frontend
flutter clean
flutter build web --release
cd ..
git add frontend/build/web
git commit -m "Rebuild with Flutter [version]"
```

### When adding new assets

Assets are automatically included in the build:

```bash
# Add asset to pubspec.yaml
# Rebuild
cd frontend
flutter build web --release
cd ..
git add frontend/build/web
git commit -m "Add new assets"
```

## Support

- **Git issues**: Check this document
- **Build issues**: See `BUILD_AND_DEPLOY.md`
- **Deployment issues**: See `VERCEL_DEPLOYMENT.md`
