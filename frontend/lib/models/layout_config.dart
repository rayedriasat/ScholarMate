import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Screen size categories for responsive design
enum ScreenSize { mobile, tablet, desktop }

/// Configuration for responsive layouts based on screen width
/// Handles breakpoint detection, grid columns, card sizing, and padding
class LayoutConfig {
  final ScreenSize screenSize;
  final double width;
  final int gridColumns;
  final double cardWidth;
  final EdgeInsets padding;
  final double touchTargetSize;

  LayoutConfig.fromWidth(this.width)
    : screenSize = _getScreenSize(width),
      gridColumns = _getGridColumns(width),
      cardWidth = _getCardWidth(width),
      padding = _getPadding(width),
      touchTargetSize = _getTouchTargetSize(width);

  /// Determine screen size category based on width
  static ScreenSize _getScreenSize(double width) {
    if (width < DesignTokens.mobileBreakpoint) return ScreenSize.mobile;
    if (width < DesignTokens.tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// Calculate number of grid columns based on screen width
  /// Mobile: 1 column
  /// Small tablet: 2 columns
  /// Large tablet: 3 columns
  /// Small desktop: 4 columns
  /// Large desktop: 5 columns
  /// Extra large: 6 columns
  static int _getGridColumns(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    if (width < 1600) return 4;
    if (width < 2000) return 5;
    return 6;
  }

  /// Calculate card width based on screen width and grid columns
  static double _getCardWidth(double width) {
    if (width < 600) return width - 32;
    final columns = _getGridColumns(width);
    return (width - 64) / columns;
  }

  /// Get padding based on screen size
  static EdgeInsets _getPadding(double width) {
    if (width < DesignTokens.mobileBreakpoint) {
      return EdgeInsets.all(DesignTokens.space4);
    }
    if (width < DesignTokens.tabletBreakpoint) {
      return EdgeInsets.all(DesignTokens.space6);
    }
    return EdgeInsets.all(DesignTokens.space8);
  }

  /// Get platform-specific touch target size
  /// Mobile platforms need larger touch targets (48dp)
  /// Desktop platforms can use smaller targets (32dp)
  static double _getTouchTargetSize(double width) {
    if (width < DesignTokens.tabletBreakpoint) {
      return DesignTokens.touchTargetMobile;
    }
    return DesignTokens.touchTargetDesktop;
  }

  /// Check if current screen is mobile
  bool get isMobile => screenSize == ScreenSize.mobile;

  /// Check if current screen is tablet
  bool get isTablet => screenSize == ScreenSize.tablet;

  /// Check if current screen is desktop
  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// Check if screen is mobile or tablet (not desktop)
  bool get isMobileOrTablet => !isDesktop;

  @override
  String toString() {
    return 'LayoutConfig(screenSize: $screenSize, width: $width, '
        'gridColumns: $gridColumns, cardWidth: $cardWidth, '
        'padding: $padding, touchTargetSize: $touchTargetSize)';
  }
}
