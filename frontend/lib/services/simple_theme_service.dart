import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';

/// Simple theme service with custom accent color support
class SimpleThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _accentColorKey = 'app_accent_color';

  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = AppColors.primary;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Initialize theme service and load saved theme
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTheme();
  }

  /// Load theme from shared preferences
  Future<void> _loadTheme() async {
    final themeIndex = _prefs?.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    final accentColorValue = _prefs?.getInt(_accentColorKey);
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }

    notifyListeners();
  }

  /// Save theme to shared preferences
  Future<void> _saveTheme() async {
    await _prefs?.setInt(_themeKey, _themeMode.index);
    await _prefs?.setInt(_accentColorKey, _accentColor.value);
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveTheme();
      notifyListeners();
    }
  }

  /// Set accent color
  Future<void> setAccentColor(Color color) async {
    if (_accentColor != color) {
      _accentColor = color;
      await _saveTheme();
      notifyListeners();
    }
  }

  /// Set light theme
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Set dark theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Set system theme
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Get light theme data
  ThemeData get lightTheme {
    return AppTheme.getLightTheme(_accentColor);
  }

  /// Get dark theme data
  ThemeData get darkTheme {
    return AppTheme.getDarkTheme(_accentColor);
  }
}
