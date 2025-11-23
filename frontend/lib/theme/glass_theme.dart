import 'package:flutter/material.dart';

/// Configuration for glassmorphism effects
/// Includes blur, opacity, gradients, and border styling
class GlassThemeConfig {
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final LinearGradient gradient;
  final Color borderColor;
  final double borderWidth;

  const GlassThemeConfig({
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    required this.gradient,
    this.borderColor = const Color(0x33FFFFFF),
    this.borderWidth = 1.0,
  });

  /// Light theme glass configuration
  /// Uses white gradients with higher opacity for light backgrounds
  factory GlassThemeConfig.light() {
    return GlassThemeConfig(
      blur: 10.0,
      opacity: 0.15,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
      ),
      borderColor: const Color(0x33FFFFFF),
    );
  }

  /// Dark theme glass configuration
  /// Uses white gradients with lower opacity for dark backgrounds
  factory GlassThemeConfig.dark() {
    return GlassThemeConfig(
      blur: 10.0,
      opacity: 0.1,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
      ),
      borderColor: const Color(0x1AFFFFFF),
    );
  }

  /// Midnight blue theme glass configuration
  factory GlassThemeConfig.midnightBlue() {
    return GlassThemeConfig(
      blur: 10.0,
      opacity: 0.12,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1E3A8A).withOpacity(0.15),
          const Color(0xFF1E3A8A).withOpacity(0.08),
        ],
      ),
      borderColor: const Color(0x33FFFFFF),
    );
  }

  /// Forest green theme glass configuration
  factory GlassThemeConfig.forestGreen() {
    return GlassThemeConfig(
      blur: 10.0,
      opacity: 0.12,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF166534).withOpacity(0.15),
          const Color(0xFF166534).withOpacity(0.08),
        ],
      ),
      borderColor: const Color(0x33FFFFFF),
    );
  }

  /// Sunset orange theme glass configuration
  factory GlassThemeConfig.sunsetOrange() {
    return GlassThemeConfig(
      blur: 10.0,
      opacity: 0.12,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEA580C).withOpacity(0.15),
          const Color(0xFFEA580C).withOpacity(0.08),
        ],
      ),
      borderColor: const Color(0x33FFFFFF),
    );
  }

  /// Copy with method for customization
  GlassThemeConfig copyWith({
    double? blur,
    double? opacity,
    BorderRadius? borderRadius,
    LinearGradient? gradient,
    Color? borderColor,
    double? borderWidth,
  }) {
    return GlassThemeConfig(
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      borderRadius: borderRadius ?? this.borderRadius,
      gradient: gradient ?? this.gradient,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }
}
