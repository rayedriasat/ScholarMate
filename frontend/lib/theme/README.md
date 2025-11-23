# ScholarMate Design System Foundation

This directory contains the design system foundation for the ScholarMate modern UI redesign.

## Files

### `theme_config.dart` (Model)
Theme configuration model with:
- **Serialization**: `toJson()` and `fromJson()` for persistence
- **Predefined Presets**: Light, Dark, Midnight Blue, Forest Green, Sunset Orange
- **Customization**: Support for custom accent colors and background images
- **Equality**: Proper `==` and `hashCode` implementations
- **Immutability**: Uses `copyWith()` for modifications

### `design_tokens.dart`
Core design tokens including:
- **Color Palettes**: Tailwind-inspired 50-900 shades for primary, secondary, accent, success, warning, error, and neutral colors
- **Typography**: Inter font family with weights (300, 400, 500, 600, 700)
- **Spacing Scale**: 4px-based spacing system (4, 8, 12, 16, 24, 32, 48, 64)
- **Border Radius**: Small (4px), Medium (8px), Large (12px), XLarge (16px), Full (9999px)
- **Breakpoints**: Mobile (<600px), Tablet (600-1024px), Desktop (>1024px)
- **Touch Targets**: Mobile (48dp), Desktop (32dp)
- **Animation Durations**: Hover (200ms), Route (300ms), Dialog (250ms)

### `glass_theme.dart`
Glassmorphism configuration with:
- Default blur (10px) and opacity (10%)
- Light theme preset (higher opacity for light backgrounds)
- Dark theme preset (lower opacity for dark backgrounds)
- Custom theme presets (Midnight Blue, Forest Green, Sunset Orange)
- Configurable gradients, borders, and border radius

### `theme_presets.dart`
Predefined Material 3 themes:
- **Light Theme**: White/light gray backgrounds with dark text
- **Dark Theme**: Dark gray/black backgrounds with light text
- **Midnight Blue**: Dark blue themed preset
- **Forest Green**: Dark green themed preset
- **Sunset Orange**: Dark orange themed preset
- All themes support custom accent colors
- Consistent typography using Inter font
- Zero-elevation cards with rounded corners

### `app_theme.dart`
Main theme provider with:
- **Theme Management**: Uses `ThemeConfig` model for theme state
- **Persistence**: Automatic save/load using SharedPreferences
- **Legacy Migration**: Automatically migrates old enum-based themes
- **Accent Color Customization**: Per-theme accent color support
- **Glass Theme Access**: Provides matching glass configurations
- **Context Extensions**: Easy access via `context.themeProvider` and `context.glassTheme`
- **Backward Compatibility**: Maintains `AppThemeMode` enum for existing code

## Usage

### Initialize Theme Provider

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final themeProvider = AppThemeProvider();
  await themeProvider.initialize();
  
  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: MyApp(),
    ),
  );
}
```

### Using ThemeConfig Model

```dart
// Create a custom theme configuration
final customTheme = ThemeConfig(
  id: 'custom',
  name: 'My Custom Theme',
  mode: ThemeMode.dark,
  accentColor: Colors.purple,
);

// Apply the theme
await context.themeProvider.setThemeConfig(customTheme);

// Serialize for storage or sync
final json = customTheme.toJson();
final restored = ThemeConfig.fromJson(json);

// Use predefined presets
await context.themeProvider.setThemeConfig(ThemeConfig.midnightBlue);
```

### Use Theme in App

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          theme: themeProvider.themeData,
          home: HomeScreen(),
        );
      },
    );
  }
}
```

### Access Design Tokens

```dart
// Spacing
Container(
  padding: EdgeInsets.all(DesignTokens.space4),
  margin: EdgeInsets.symmetric(vertical: DesignTokens.space2),
)

// Colors
Container(
  color: DesignTokens.primary[500],
)

// Border Radius
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
  ),
)
```

### Access Glass Theme

```dart
Widget build(BuildContext context) {
  final glassTheme = context.glassTheme;
  
  return Container(
    decoration: BoxDecoration(
      gradient: glassTheme.gradient,
      borderRadius: glassTheme.borderRadius,
      border: Border.all(
        color: glassTheme.borderColor,
        width: glassTheme.borderWidth,
      ),
    ),
  );
}
```

### Switch Themes

```dart
// Method 1: Using ThemeConfig (recommended)
await context.themeProvider.setThemeConfig(ThemeConfig.dark);

// Method 2: Using AppThemeMode (backward compatibility)
await context.themeProvider.setThemeMode(AppThemeMode.dark);

// Set custom accent color
await context.themeProvider.setAccentColor(Colors.purple);

// Get current theme config
final currentTheme = context.watchThemeProvider.currentTheme;
print('Current theme: ${currentTheme.name}');

// Get all available presets
final presets = ThemeConfig.allPresets;

// Reset to defaults
await context.themeProvider.resetToDefaults();
```

## Testing

All design tokens and theme configurations are tested:
- Spacing values are verified to be multiples of 4px
- Color palettes have all required shades (50-900)
- Typography uses Inter font family
- Glass theme configurations have correct defaults
- Theme presets use Material 3 and correct brightness

Run tests:
```bash
flutter test test/theme/
```

## Requirements Satisfied

This implementation satisfies the following requirements from the design document:

- **1.1**: Design tokens with color palettes, typography, spacing, and border radius
- **1.2**: Tailwind-inspired color palette with 50-900 shades
- **1.3**: Inter font family with weights 300, 400, 500, 600, 700
- **1.4**: Spacing scale using multiples of 4px (verified by tests)
- **1.5**: Border radius values for small, medium, large, and extra-large components

## Next Steps

The next task will implement the core glass components (cards, buttons, inputs, dialogs) using these design tokens and glass theme configurations.
