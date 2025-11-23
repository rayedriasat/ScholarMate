import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_tokens.dart';
import 'glass_theme.dart';
import 'theme_presets.dart';

/// Theme mode enumeration
enum AppThemeMode { light, dark, midnightBlue, forestGreen, sunsetOrange }

/// Main theme provider for the application
/// Manages theme switching, persistence, and glass configuration
class AppThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _accentColorKey = 'app_accent_color';

  AppThemeMode _themeMode = AppThemeMode.light;
  Color _accentColor = DesignTokens.accent[500]!;
  late SharedPreferences _prefs;

  AppThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  /// Get the current ThemeData based on selected mode
  ThemeData get themeData {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemePresets.light(accentColor: _accentColor);
      case AppThemeMode.dark:
        return ThemePresets.dark(accentColor: _accentColor);
      case AppThemeMode.midnightBlue:
        return ThemePresets.midnightBlue(accentColor: _accentColor);
      case AppThemeMode.forestGreen:
        return ThemePresets.forestGreen(accentColor: _accentColor);
      case AppThemeMode.sunsetOrange:
        return ThemePresets.sunsetOrange(accentColor: _accentColor);
    }
  }

  /// Get the current glass theme configuration
  GlassThemeConfig get glassTheme {
    switch (_themeMode) {
      case AppThemeMode.light:
        return GlassThemeConfig.light();
      case AppThemeMode.dark:
        return GlassThemeConfig.dark();
      case AppThemeMode.midnightBlue:
        return GlassThemeConfig.midnightBlue();
      case AppThemeMode.forestGreen:
        return GlassThemeConfig.forestGreen();
      case AppThemeMode.sunsetOrange:
        return GlassThemeConfig.sunsetOrange();
    }
  }

  /// Initialize the theme provider and load saved preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadThemePreferences();
  }

  /// Load theme preferences from storage
  Future<void> _loadThemePreferences() async {
    final themeModeIndex = _prefs.getInt(_themeModeKey);
    if (themeModeIndex != null && themeModeIndex < AppThemeMode.values.length) {
      _themeMode = AppThemeMode.values[themeModeIndex];
    }

    final accentColorValue = _prefs.getInt(_accentColorKey);
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }

    notifyListeners();
  }

  /// Set the theme mode and persist to storage
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }

  /// Set the accent color and persist to storage
  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _prefs.setInt(_accentColorKey, color.value);
    notifyListeners();
  }

  /// Reset to default theme settings
  Future<void> resetToDefaults() async {
    _themeMode = AppThemeMode.light;
    _accentColor = DesignTokens.accent[500]!;
    await _prefs.remove(_themeModeKey);
    await _prefs.remove(_accentColorKey);
    notifyListeners();
  }

  /// Check if current theme is dark
  bool get isDark {
    return _themeMode != AppThemeMode.light;
  }

  /// Get theme mode display name
  String getThemeModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.midnightBlue:
        return 'Midnight Blue';
      case AppThemeMode.forestGreen:
        return 'Forest Green';
      case AppThemeMode.sunsetOrange:
        return 'Sunset Orange';
    }
  }
}

/// Extension to easily access theme provider from context
extension ThemeContext on BuildContext {
  AppThemeProvider get themeProvider =>
      Provider.of<AppThemeProvider>(this, listen: false);
  AppThemeProvider get watchThemeProvider =>
      Provider.of<AppThemeProvider>(this);
  GlassThemeConfig get glassTheme => watchThemeProvider.glassTheme;
}
