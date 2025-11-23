import 'package:flutter/material.dart';

/// Animation duration and curve constants for consistent animations throughout the app
class AnimationConstants {
  // Duration constants
  static const Duration hoverDuration = Duration(milliseconds: 200);
  static const Duration routeTransitionDuration = Duration(milliseconds: 300);
  static const Duration dialogDuration = Duration(milliseconds: 250);
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration listItemDuration = Duration(milliseconds: 300);

  // Curve constants
  static const Curve defaultCurve = Curves.easeOut;
  static const Curve dialogCurve = Curves.easeInOut;
  static const Curve springCurve = Curves.elasticOut;

  // Scale constants
  static const double hoverScale = 1.02;
  static const double hoverOpacity = 0.9;

  // Shimmer constants
  static const double shimmerBegin = -1.0;
  static const double shimmerEnd = 2.0;

  /// Check if reduced motion is enabled in system accessibility settings
  static bool isReducedMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get animation duration based on reduced motion preference
  /// Returns Duration.zero if reduced motion is enabled, otherwise returns the specified duration
  static Duration getAnimationDuration(
    BuildContext context,
    Duration duration,
  ) {
    return isReducedMotionEnabled(context) ? Duration.zero : duration;
  }

  /// Get curve based on reduced motion preference
  /// Returns linear curve if reduced motion is enabled, otherwise returns the specified curve
  static Curve getAnimationCurve(BuildContext context, Curve curve) {
    return isReducedMotionEnabled(context) ? Curves.linear : curve;
  }
}
