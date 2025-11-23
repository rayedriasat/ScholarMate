import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Predefined theme configurations for ScholarMate
/// Includes light, dark, and custom themed presets
class ThemePresets {
  // Prevent instantiation
  ThemePresets._();

  /// Light theme preset
  static ThemeData light({Color? accentColor}) {
    final accent = accentColor ?? DesignTokens.accent[500]!;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: DesignTokens.primary[500]!,
        onPrimary: Colors.white,
        secondary: DesignTokens.secondary[500]!,
        onSecondary: Colors.white,
        tertiary: accent,
        onTertiary: Colors.white,
        error: DesignTokens.error[500]!,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: DesignTokens.neutral[900]!,
        surfaceContainerHighest: DesignTokens.neutral[100]!,
      ),
      scaffoldBackgroundColor: DesignTokens.neutral[50]!,
      fontFamily: DesignTokens.fontFamily,
      textTheme: _buildTextTheme(DesignTokens.neutral[900]!),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: DesignTokens.neutral[900]!,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space6,
            vertical: DesignTokens.space3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.neutral[100]!,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
    );
  }

  /// Dark theme preset
  static ThemeData dark({Color? accentColor}) {
    final accent = accentColor ?? DesignTokens.accent[500]!;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: DesignTokens.primary[400]!,
        onPrimary: DesignTokens.neutral[900]!,
        secondary: DesignTokens.secondary[400]!,
        onSecondary: DesignTokens.neutral[900]!,
        tertiary: accent,
        onTertiary: DesignTokens.neutral[900]!,
        error: DesignTokens.error[400]!,
        onError: DesignTokens.neutral[900]!,
        surface: DesignTokens.neutral[900]!,
        onSurface: DesignTokens.neutral[50]!,
        surfaceContainerHighest: DesignTokens.neutral[800]!,
      ),
      scaffoldBackgroundColor: DesignTokens.neutral[900]!,
      fontFamily: DesignTokens.fontFamily,
      textTheme: _buildTextTheme(DesignTokens.neutral[50]!),
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.neutral[900]!,
        foregroundColor: DesignTokens.neutral[50]!,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: DesignTokens.neutral[800]!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space6,
            vertical: DesignTokens.space3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.neutral[800]!,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
      ),
    );
  }

  /// Midnight blue theme preset
  static ThemeData midnightBlue({Color? accentColor}) {
    final accent = accentColor ?? DesignTokens.accent[500]!;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF3B82F6),
        onPrimary: Colors.white,
        secondary: DesignTokens.secondary[400]!,
        onSecondary: Colors.white,
        tertiary: accent,
        onTertiary: Colors.white,
        error: DesignTokens.error[400]!,
        onError: Colors.white,
        surface: const Color(0xFF1E3A8A),
        onSurface: const Color(0xFFE0E7FF),
        surfaceContainerHighest: const Color(0xFF1E40AF),
      ),
      scaffoldBackgroundColor: const Color(0xFF172554),
      fontFamily: DesignTokens.fontFamily,
      textTheme: _buildTextTheme(const Color(0xFFE0E7FF)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Color(0xFFE0E7FF),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E40AF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
      ),
    );
  }

  /// Forest green theme preset
  static ThemeData forestGreen({Color? accentColor}) {
    final accent = accentColor ?? DesignTokens.accent[500]!;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF22C55E),
        onPrimary: Colors.white,
        secondary: DesignTokens.secondary[400]!,
        onSecondary: Colors.white,
        tertiary: accent,
        onTertiary: Colors.white,
        error: DesignTokens.error[400]!,
        onError: Colors.white,
        surface: const Color(0xFF166534),
        onSurface: const Color(0xFFDCFCE7),
        surfaceContainerHighest: const Color(0xFF15803D),
      ),
      scaffoldBackgroundColor: const Color(0xFF14532D),
      fontFamily: DesignTokens.fontFamily,
      textTheme: _buildTextTheme(const Color(0xFFDCFCE7)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF166534),
        foregroundColor: Color(0xFFDCFCE7),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF15803D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
      ),
    );
  }

  /// Sunset orange theme preset
  static ThemeData sunsetOrange({Color? accentColor}) {
    final accent = accentColor ?? DesignTokens.accent[500]!;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFFB923C),
        onPrimary: Colors.white,
        secondary: DesignTokens.secondary[400]!,
        onSecondary: Colors.white,
        tertiary: accent,
        onTertiary: Colors.white,
        error: DesignTokens.error[400]!,
        onError: Colors.white,
        surface: const Color(0xFFEA580C),
        onSurface: const Color(0xFFFED7AA),
        surfaceContainerHighest: const Color(0xFFC2410C),
      ),
      scaffoldBackgroundColor: const Color(0xFF9A3412),
      fontFamily: DesignTokens.fontFamily,
      textTheme: _buildTextTheme(const Color(0xFFFED7AA)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFEA580C),
        foregroundColor: Color(0xFFFED7AA),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFFC2410C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
      ),
    );
  }

  /// Build text theme with consistent typography
  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: DesignTokens.bold,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: DesignTokens.bold,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: DesignTokens.bold,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: DesignTokens.semiBold,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: DesignTokens.semiBold,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: DesignTokens.semiBold,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: DesignTokens.medium,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: DesignTokens.medium,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: DesignTokens.medium,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: DesignTokens.regular,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: DesignTokens.regular,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: DesignTokens.regular,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: DesignTokens.medium,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: DesignTokens.medium,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: DesignTokens.medium,
        color: baseColor,
        fontFamily: DesignTokens.fontFamily,
      ),
    );
  }
}
