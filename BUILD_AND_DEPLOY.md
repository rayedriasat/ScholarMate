# Build and Deploy Guide

This guide explains how to build and deploy the Flutter web app to Vercel using prebuilt files.

## Why Prebuilt Files?

We commit the built web files (`frontend/build/web`) to git because:
- ✅ Faster deployments (~30 seconds vs 5+ minutes)
- ✅ Consistent builds (same environment every time)
- ✅ No Flutter installation needed on Vercel
- ✅ Easier debugging (you see exactly what's deployed)
- ✅ Lower resource usage on Vercel

## Quick Build & Deploy

### Option 1: Automated Script (Recommended)

**Windows:**
```bash
build-and-deploy.bat
git push origin main
vercel --prod
```

**Linux/Mac:**
```bash
chmod +x build-and-deploy.sh
./build-and-deploy.sh
git push origin main
vercel --prod
```

### Option 2: Manual Steps

```bash
# 1. Build the web app
cd frontend
flutter build web --release --web-renderer canvaskit
cd ..

# 2. Commit the build
git add frontend/build/web
git commit -m "Build web app for deployment"

# 3. Push to git
git push origin main

# 4. Deploy to Vercel
vercel --prod
```

## Build Configuration

### Web Renderer
We use `canvaskit` renderer for better compatibility:
```bash
flutter build web --release --web-renderer canvaskit
```

**Alternatives:**
- `--web-renderer html` - Smaller size, limited features
- `--web-renderer auto` - Flutter decides (not recommended for production)

### Build Output
The build creates these files in `frontend/build/web/`:
```
frontend/build/web/
├── index.html          # Main HTML file
├── main.dart.js        # Compiled Dart code
├── flutter.js          # Flutter engine
├── canvaskit/          # CanvasKit WASM files
├── assets/             # App assets
└── ...
```

## Git Configuration

The `.gitignore` is configured to:
- ❌ Exclude all `build/` folders by default
- ✅ Force-include `frontend/build/web/` specifically

```gitignore
# Exclude all builds
build/

# EXCEPT: Force include prebuilt web
!frontend/build/
!frontend/build/web/
!frontend/build/web/**
```

## Vercel Configuration

The `vercel.json` is configured for prebuilt files:
```json
{
  "buildCommand": null,
  "outputDirectory": "frontend/build/web",
  "framework": null
}
```

## Deployment Workflow

### First-Time Deployment

1. **Build locally**
   ```bash
   cd frontend
   flutter build web --release --web-renderer canvaskit
   cd ..
   ```

2. **Commit build folder**
   ```bash
   git add frontend/build/web
   git commit -m "Initial web build for Vercel"
   git push origin main
   ```

3. **Deploy to Vercel**
   ```bash
   vercel --prod
   ```

### Updating Deployment

When you make code changes:

1. **Make your changes** in `frontend/lib/`

2. **Rebuild**
   ```bash
   cd frontend
   flutter build web --release --web-renderer canvaskit
   cd ..
   ```

3. **Commit and push**
   ```bash
   git add frontend/build/web
   git commit -m "Update: [describe your changes]"
   git push origin main
   ```

4. **Vercel auto-deploys** (or run `vercel --prod`)

## Build Optimization

### Reduce Build Size

1. **Enable tree shaking** (already enabled in release mode)
2. **Optimize images** before adding to assets
3. **Remove unused dependencies** from `pubspec.yaml`
4. **Use web-specific assets** when possible

### Build Performance

- **Clean build**: `flutter clean && flutter build web --release`
- **Incremental builds**: Just `flutter build web --release`
- **Parallel builds**: Not applicable for web

## Troubleshooting

### Build Fails

**Error: Flutter not found**
```bash
# Verify Flutter installation
flutter --version

# Add Flutter to PATH if needed
```

**Error: Dependencies not resolved**
```bash
cd frontend
flutter pub get
flutter build web --release
```

**Error: Out of memory**
```bash
# Increase memory for build
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false
```

### Git Issues

**Error: Build folder not tracked**
```bash
# Verify .gitignore configuration
git check-ignore -v frontend/build/web/index.html

# Should show: (no output means it's tracked)
```

**Error: Large commit size**
```bash
# This is normal - web builds are ~10-50 MB
# Git handles this fine, but consider Git LFS for very large assets
```

### Deployment Issues

**Error: 404 on Vercel**
- Verify `vercel.json` points to `frontend/build/web`
- Check that `index.html` exists in build folder
- Ensure build folder is committed to git

**Error: Blank page**
- Check browser console for errors
- Verify base href in `index.html`
- Check that all assets are included in build

## Best Practices

### ✅ Do

- Build locally before every deployment
- Commit build folder with descriptive messages
- Test locally before pushing: `vercel dev`
- Keep Flutter SDK updated
- Use `--release` mode for production

### ❌ Don't

- Don't commit `.env` files
- Don't skip the build step
- Don't use `--debug` mode for production
- Don't manually edit files in `build/web/`
- Don't forget to test after building

## Automated CI/CD (Optional)

If you want to automate builds:

### GitHub Actions Example

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Build web
        run: |
          cd frontend
          flutter pub get
          flutter build web --release --web-renderer canvaskit
      
      - name: Commit build
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add frontend/build/web
          git commit -m "Auto-build: ${{ github.sha }}" || echo "No changes"
          git push
```

**Note**: This requires careful setup to avoid infinite loops.

## Performance Metrics

### Build Time
- Clean build: ~2-5 minutes
- Incremental build: ~30-60 seconds

### Deployment Time
- Vercel deployment: ~30 seconds
- Total time (build + deploy): ~3-6 minutes

### Build Size
- Typical size: 10-50 MB
- With assets: 50-200 MB
- Compressed (gzip): ~3-15 MB

## Support

- **Build issues**: Check Flutter docs
- **Git issues**: See `.gitignore` configuration
- **Deployment issues**: See `VERCEL_DEPLOYMENT.md`
- **General help**: See `VERCEL_QUICK_START.md`

---

## Quick Reference

```bash
# Build
cd frontend && flutter build web --release --web-renderer canvaskit && cd ..

# Commit
git add frontend/build/web && git commit -m "Build for deployment"

# Push
git push origin main

# Deploy
vercel --prod

# All in one (Windows)
build-and-deploy.bat && git push && vercel --prod

# All in one (Linux/Mac)
./build-and-deploy.sh && git push && vercel --prod
```
