import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_config.dart';
import 'design_tokens.dart';
import 'glass_theme.dart';
import 'theme_presets.dart';

/// Theme mode enumeration (kept for backward compatibility)
enum AppThemeMode { light, dark, midnightBlue, forestGreen, sunsetOrange }

/// Main theme provider for the application
/// Manages theme switching, persistence, and glass configuration
class AppThemeProvider extends ChangeNotifier {
  static const String _themeConfigKey = 'app_theme_config';
  static const String _themeModeKey = 'app_theme_mode'; // Legacy key
  static const String _accentColorKey = 'app_accent_color'; // Legacy key

  ThemeConfig _currentTheme = ThemeConfig.defaultLight;
  late SharedPreferences _prefs;

  ThemeConfig get currentTheme => _currentTheme;
  AppThemeMode get themeMode => _themeIdToMode(_currentTheme.id);
  Color get accentColor => _currentTheme.accentColor;

  /// Get the current ThemeData based on selected theme config
  ThemeData get themeData {
    switch (_currentTheme.id) {
      case 'light':
        return ThemePresets.light(accentColor: _currentTheme.accentColor);
      case 'dark':
        return ThemePresets.dark(accentColor: _currentTheme.accentColor);
      case 'midnight_blue':
        return ThemePresets.midnightBlue(
          accentColor: _currentTheme.accentColor,
        );
      case 'forest_green':
        return ThemePresets.forestGreen(accentColor: _currentTheme.accentColor);
      case 'sunset_orange':
        return ThemePresets.sunsetOrange(
          accentColor: _currentTheme.accentColor,
        );
      default:
        return ThemePresets.light(accentColor: _currentTheme.accentColor);
    }
  }

  /// Get the current glass theme configuration
  GlassThemeConfig get glassTheme {
    switch (_currentTheme.id) {
      case 'light':
        return GlassThemeConfig.light();
      case 'dark':
        return GlassThemeConfig.dark();
      case 'midnight_blue':
        return GlassThemeConfig.midnightBlue();
      case 'forest_green':
        return GlassThemeConfig.forestGreen();
      case 'sunset_orange':
        return GlassThemeConfig.sunsetOrange();
      default:
        return GlassThemeConfig.light();
    }
  }

  /// Initialize the theme provider and load saved preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadThemePreferences();
  }

  /// Load theme preferences from storage
  Future<void> _loadThemePreferences() async {
    // Try to load new format first
    final themeConfigJson = _prefs.getString(_themeConfigKey);
    if (themeConfigJson != null) {
      try {
        final json = jsonDecode(themeConfigJson) as Map<String, dynamic>;
        _currentTheme = ThemeConfig.fromJson(json);
        notifyListeners();
        return;
      } catch (e) {
        // If parsing fails, fall back to legacy format
        debugPrint('Failed to parse theme config: $e');
      }
    }

    // Legacy format migration
    final themeModeIndex = _prefs.getInt(_themeModeKey);
    final accentColorValue = _prefs.getInt(_accentColorKey);

    if (themeModeIndex != null && themeModeIndex < AppThemeMode.values.length) {
      final mode = AppThemeMode.values[themeModeIndex];
      final accent = accentColorValue != null
          ? Color(accentColorValue)
          : DesignTokens.accent[500]!;

      _currentTheme = _modeToThemeConfig(mode, accent);

      // Save in new format and remove legacy keys
      await _saveThemeConfig();
      await _prefs.remove(_themeModeKey);
      await _prefs.remove(_accentColorKey);
    }

    notifyListeners();
  }

  /// Save theme configuration to storage
  Future<void> _saveThemeConfig() async {
    final json = jsonEncode(_currentTheme.toJson());
    await _prefs.setString(_themeConfigKey, json);
  }

  /// Set the theme configuration and persist to storage
  Future<void> setThemeConfig(ThemeConfig config) async {
    _currentTheme = config;
    await _saveThemeConfig();
    notifyListeners();
  }

  /// Set the theme mode and persist to storage (backward compatibility)
  Future<void> setThemeMode(AppThemeMode mode) async {
    _currentTheme = _modeToThemeConfig(mode, _currentTheme.accentColor);
    await _saveThemeConfig();
    notifyListeners();
  }

  /// Set the accent color and persist to storage
  Future<void> setAccentColor(Color color) async {
    _currentTheme = _currentTheme.copyWith(accentColor: color);
    await _saveThemeConfig();
    notifyListeners();
  }

  /// Reset to default theme settings
  Future<void> resetToDefaults() async {
    _currentTheme = ThemeConfig.defaultLight;
    await _prefs.remove(_themeConfigKey);
    await _prefs.remove(_themeModeKey);
    await _prefs.remove(_accentColorKey);
    notifyListeners();
  }

  /// Check if current theme is dark
  bool get isDark {
    return _currentTheme.mode == ThemeMode.dark;
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

  /// Convert AppThemeMode to ThemeConfig
  ThemeConfig _modeToThemeConfig(AppThemeMode mode, Color accentColor) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeConfig.defaultLight.copyWith(accentColor: accentColor);
      case AppThemeMode.dark:
        return ThemeConfig.defaultDark.copyWith(accentColor: accentColor);
      case AppThemeMode.midnightBlue:
        return ThemeConfig.midnightBlue.copyWith(accentColor: accentColor);
      case AppThemeMode.forestGreen:
        return ThemeConfig.forestGreen.copyWith(accentColor: accentColor);
      case AppThemeMode.sunsetOrange:
        return ThemeConfig.sunsetOrange.copyWith(accentColor: accentColor);
    }
  }

  /// Convert theme ID to AppThemeMode
  AppThemeMode _themeIdToMode(String id) {
    switch (id) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'midnight_blue':
        return AppThemeMode.midnightBlue;
      case 'forest_green':
        return AppThemeMode.forestGreen;
      case 'sunset_orange':
        return AppThemeMode.sunsetOrange;
      default:
        return AppThemeMode.light;
    }
  }

  /// Get all available theme presets
  List<ThemeConfig> get availableThemes => ThemeConfig.allPresets;
}

/// Extension to easily access theme provider from context
extension ThemeContext on BuildContext {
  AppThemeProvider get themeProvider =>
      Provider.of<AppThemeProvider>(this, listen: false);
  AppThemeProvider get watchThemeProvider =>
      Provider.of<AppThemeProvider>(this);
  GlassThemeConfig get glassTheme => watchThemeProvider.glassTheme;
}
