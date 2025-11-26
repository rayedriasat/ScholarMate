# Setting ScholarMate App Icon

## Quick Setup

### Step 1: Prepare Your Logo
1. Create or obtain a ScholarMate logo (PNG format)
2. Recommended size: **1024x1024 pixels**
3. Should have transparent background or solid color
4. Save it as `scholarmate_logo.png`

### Step 2: Add Logo to Assets
Place your logo file here:
```
frontend/assets/scholarmate_logo.png
```

### Step 3: Generate Icons
Run this command from the `frontend` directory:
```bash
flutter pub run flutter_launcher_icons
```

This will automatically generate all required icon sizes for:
- Android (all densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- iOS (all sizes)
- Adaptive icons for Android 8.0+

### Step 4: Rebuild Your App
```bash
flutter clean
flutter pub get
flutter build apk
```

## Configuration Details

The icon configuration is in `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/scholarmate_logo.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/scholarmate_logo.png"
```

## Customization Options

### Change Background Color
Edit the `adaptive_icon_background` value in `pubspec.yaml`:
```yaml
adaptive_icon_background: "#2196F3"  # Blue background
```

### Different Icons for Android/iOS
```yaml
flutter_launcher_icons:
  android: "assets/android_icon.png"
  ios: "assets/ios_icon.png"
```

### Remove iOS Icons (Android Only)
```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/scholarmate_logo.png"
```

## Troubleshooting

### Icons Not Updating
1. Run `flutter clean`
2. Delete `build` folder
3. Regenerate icons: `flutter pub run flutter_launcher_icons`
4. Rebuild app

### Logo Looks Stretched
- Ensure your logo is square (1024x1024)
- Add padding around the logo in your image editor
- Use transparent background

### Adaptive Icon Issues (Android)
- The foreground image should have padding (safe zone)
- Background color should complement your logo
- Test on Android 8.0+ devices

## Design Tips

1. **Keep it simple**: Icons look best when simple and recognizable
2. **High contrast**: Ensure logo stands out on various backgrounds
3. **No text**: Avoid small text in icons (hard to read)
4. **Test on device**: Always test on actual devices
5. **Safe zone**: Keep important elements in center 66% of canvas

## Quick Logo Creation Tools

If you need to create a logo quickly:
- **Canva**: https://www.canva.com (free templates)
- **Figma**: https://www.figma.com (design tool)
- **Logo Maker**: https://www.freelogodesign.org
- **Icon Generator**: https://icon.kitchen (Android adaptive icons)

## Current Status

✅ `flutter_launcher_icons` package installed
✅ Configuration added to `pubspec.yaml`
⏳ Waiting for logo file: `frontend/assets/scholarmate_logo.png`

Once you add the logo file, run:
```bash
cd frontend
flutter pub run flutter_launcher_icons
```
