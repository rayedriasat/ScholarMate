import 'package:flutter/material.dart';
import '../models/layout_config.dart';
import '../theme/design_tokens.dart';

/// Utility functions for responsive design
class ResponsiveUtils {
  ResponsiveUtils._();

  /// Get LayoutConfig from current context
  static LayoutConfig getLayoutConfig(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutConfig.fromWidth(width);
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < DesignTokens.mobileBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= DesignTokens.mobileBreakpoint &&
        width < DesignTokens.tabletBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= DesignTokens.tabletBreakpoint;
  }

  /// Get screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < DesignTokens.mobileBreakpoint) return ScreenSize.mobile;
    if (width < DesignTokens.tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// Get number of grid columns for current screen
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    if (width < 1600) return 4;
    if (width < 2000) return 5;
    return 6;
  }

  /// Get responsive padding for current screen
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < DesignTokens.mobileBreakpoint) {
      return EdgeInsets.all(DesignTokens.space4);
    }
    if (width < DesignTokens.tabletBreakpoint) {
      return EdgeInsets.all(DesignTokens.space6);
    }
    return EdgeInsets.all(DesignTokens.space8);
  }

  /// Get platform-specific touch target size
  static double getTouchTargetSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < DesignTokens.tabletBreakpoint) {
      return DesignTokens.touchTargetMobile;
    }
    return DesignTokens.touchTargetDesktop;
  }

  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive spacing based on screen size
  static double getResponsiveSpacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Calculate card width for grid layout
  static double getCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return width - 32;
    final columns = getGridColumns(context);
    return (width - 64) / columns;
  }

  /// Get value based on screen size
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}
