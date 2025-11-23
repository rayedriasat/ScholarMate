import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Indigo/Violet)
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400

  // Secondary Palette (Fuchsia/Purple)
  static const Color secondary = Color(0xFFD946EF); // Fuchsia 500
  static const Color secondaryDark = Color(0xFFC026D3); // Fuchsia 600
  static const Color secondaryLight = Color(0xFFE879F9); // Fuchsia 400

  // Accent Palette (Cyan/Teal)
  static const Color accent = Color(0xFF06B6D4); // Cyan 500
  static const Color accentDark = Color(0xFF0891B2); // Cyan 600
  static const Color accentLight = Color(0xFF22D3EE); // Cyan 400

  // Neutral Palette
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceLight = Color(0xFF334155); // Slate 700
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textTertiary = Color(0xFF64748B); // Slate 500

  // Glassmorphism Colors
  static Color glassWhite = Colors.white.withValues(alpha: 0.1);
  static Color glassBlack = Colors.black.withValues(alpha: 0.2);
  static Color glassBorder = Colors.white.withValues(alpha: 0.1);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF), // white 0.1
      Color(0x0DFFFFFF), // white 0.05
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Accent Colors for Theme Customization
  static const List<Color> accentColors = [
    Color(0xFF6366F1), // Indigo (Default)
    Color(0xFF3B82F6), // Blue
    Color(0xFF0EA5E9), // Sky
    Color(0xFF06B6D4), // Cyan
    Color(0xFF14B8A6), // Teal
    Color(0xFF10B981), // Emerald
    Color(0xFF22C55E), // Green
    Color(0xFF84CC16), // Lime
    Color(0xFFEAB308), // Yellow
    Color(0xFFF59E0B), // Amber
    Color(0xFFF97316), // Orange
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFFD946EF), // Fuchsia
    Color(0xFF8B5CF6), // Violet
  ];
}
