import 'package:flutter/material.dart';

/// Design tokens for the ScholarMate application
/// Following Tailwind-inspired color palette and 4px spacing scale
class DesignTokens {
  // Prevent instantiation
  DesignTokens._();

  // ============================================================================
  // COLOR PALETTE (Tailwind-inspired with 50-900 shades)
  // ============================================================================

  /// Primary color palette (Blue)
  static const Map<int, Color> primary = {
    50: Color(0xFFF0F9FF),
    100: Color(0xFFE0F2FE),
    200: Color(0xFFBAE6FD),
    300: Color(0xFF7DD3FC),
    400: Color(0xFF38BDF8),
    500: Color(0xFF0EA5E9), // Base
    600: Color(0xFF0284C7),
    700: Color(0xFF0369A1),
    800: Color(0xFF075985),
    900: Color(0xFF0C4A6E),
  };

  /// Secondary color palette (Purple)
  static const Map<int, Color> secondary = {
    50: Color(0xFFFAF5FF),
    100: Color(0xFFF3E8FF),
    200: Color(0xFFE9D5FF),
    300: Color(0xFFD8B4FE),
    400: Color(0xFFC084FC),
    500: Color(0xFFA855F7), // Base
    600: Color(0xFF9333EA),
    700: Color(0xFF7E22CE),
    800: Color(0xFF6B21A8),
    900: Color(0xFF581C87),
  };

  /// Accent color palette (Cyan) - User customizable
  static const Map<int, Color> accent = {
    50: Color(0xFFECFEFF),
    100: Color(0xFFCFFAFE),
    200: Color(0xFFA5F3FC),
    300: Color(0xFF67E8F9),
    400: Color(0xFF22D3EE),
    500: Color(0xFF06B6D4), // Base
    600: Color(0xFF0891B2),
    700: Color(0xFF0E7490),
    800: Color(0xFF155E75),
    900: Color(0xFF164E63),
  };

  /// Success color palette (Green)
  static const Map<int, Color> success = {
    50: Color(0xFFF0FDF4),
    100: Color(0xFFDCFCE7),
    200: Color(0xFFBBF7D0),
    300: Color(0xFF86EFAC),
    400: Color(0xFF4ADE80),
    500: Color(0xFF22C55E), // Base
    600: Color(0xFF16A34A),
    700: Color(0xFF15803D),
    800: Color(0xFF166534),
    900: Color(0xFF14532D),
  };

  /// Warning color palette (Amber)
  static const Map<int, Color> warning = {
    50: Color(0xFFFFFBEB),
    100: Color(0xFFFEF3C7),
    200: Color(0xFFFDE68A),
    300: Color(0xFFFCD34D),
    400: Color(0xFFFBBF24),
    500: Color(0xFFF59E0B), // Base
    600: Color(0xFFD97706),
    700: Color(0xFFB45309),
    800: Color(0xFF92400E),
    900: Color(0xFF78350F),
  };

  /// Error color palette (Red)
  static const Map<int, Color> error = {
    50: Color(0xFFFEF2F2),
    100: Color(0xFFFEE2E2),
    200: Color(0xFFFECACA),
    300: Color(0xFFFCA5A5),
    400: Color(0xFFF87171),
    500: Color(0xFFEF4444), // Base
    600: Color(0xFFDC2626),
    700: Color(0xFFB91C1C),
    800: Color(0xFF991B1B),
    900: Color(0xFF7F1D1D),
  };

  /// Neutral color palette (Gray)
  static const Map<int, Color> neutral = {
    50: Color(0xFFFAFAFA),
    100: Color(0xFFF5F5F5),
    200: Color(0xFFE5E5E5),
    300: Color(0xFFD4D4D4),
    400: Color(0xFFA3A3A3),
    500: Color(0xFF737373), // Base
    600: Color(0xFF525252),
    700: Color(0xFF404040),
    800: Color(0xFF262626),
    900: Color(0xFF171717),
  };

  // ============================================================================
  // TYPOGRAPHY (Inter font family)
  // ============================================================================

  static const String fontFamily = 'Inter';

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // ============================================================================
  // SPACING SCALE (4px base - all values are multiples of 4)
  // ============================================================================

  static const double space1 = 4.0; // 4px
  static const double space2 = 8.0; // 8px
  static const double space3 = 12.0; // 12px
  static const double space4 = 16.0; // 16px
  static const double space6 = 24.0; // 24px
  static const double space8 = 32.0; // 32px
  static const double space12 = 48.0; // 48px
  static const double space16 = 64.0; // 64px

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusFull = 9999.0;

  // ============================================================================
  // BREAKPOINTS (for responsive design)
  // ============================================================================

  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;

  // ============================================================================
  // TOUCH TARGETS
  // ============================================================================

  static const double touchTargetMobile = 48.0;
  static const double touchTargetDesktop = 32.0;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  static const Duration hoverDuration = Duration(milliseconds: 200);
  static const Duration routeDuration = Duration(milliseconds: 300);
  static const Duration dialogDuration = Duration(milliseconds: 250);
}
