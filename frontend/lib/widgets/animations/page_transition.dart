import 'package:flutter/material.dart';
import '../../utils/animation_utils.dart';

/// Custom page route with slide and fade transition
///
/// This creates a smooth page transition that combines a slide animation
/// from right to left with a fade-in effect. The animation respects the
/// user's reduced motion accessibility preferences.
///
/// Example:
/// ```dart
/// Navigator.of(context).push(
///   SlidePageRoute(
///     builder: (context) => MyNewScreen(),
///   ),
/// );
/// ```
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final Duration duration;
  final Curve curve;

  SlidePageRoute({
    required this.builder,
    this.duration = AnimationConstants.routeTransitionDuration,
    this.curve = AnimationConstants.defaultCurve,
    RouteSettings? settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         settings: settings,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Check for reduced motion preference
           final reducedMotion = AnimationConstants.isReducedMotionEnabled(
             context,
           );

           if (reducedMotion) {
             // If reduced motion is enabled, just fade without sliding
             return FadeTransition(opacity: animation, child: child);
           }

           // Slide from right to left
           const begin = Offset(1.0, 0.0);
           const end = Offset.zero;
           final slideTween = Tween(begin: begin, end: end);
           final slideAnimation = animation.drive(
             slideTween.chain(CurveTween(curve: curve)),
           );

           // Fade in
           final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
           final fadeAnimation = animation.drive(
             fadeTween.chain(CurveTween(curve: curve)),
           );

           return SlideTransition(
             position: slideAnimation,
             child: FadeTransition(opacity: fadeAnimation, child: child),
           );
         },
       );
}

/// Custom dialog route with scale and fade transition
///
/// This creates a smooth dialog transition that combines a scale animation
/// with a fade-in effect. The animation respects the user's reduced motion
/// accessibility preferences.
///
/// Example:
/// ```dart
/// Navigator.of(context).push(
///   ScaleDialogRoute(
///     builder: (context) => MyDialog(),
///   ),
/// );
/// ```
class ScaleDialogRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final Duration duration;
  final Curve curve;

  ScaleDialogRoute({
    required this.builder,
    this.duration = AnimationConstants.dialogDuration,
    this.curve = AnimationConstants.dialogCurve,
    RouteSettings? settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         opaque: false,
         barrierDismissible: true,
         barrierColor: Colors.black54,
         settings: settings,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Check for reduced motion preference
           final reducedMotion = AnimationConstants.isReducedMotionEnabled(
             context,
           );

           if (reducedMotion) {
             // If reduced motion is enabled, just fade without scaling
             return FadeTransition(opacity: animation, child: child);
           }

           // Scale from 0.8 to 1.0
           final scaleTween = Tween<double>(begin: 0.8, end: 1.0);
           final scaleAnimation = animation.drive(
             scaleTween.chain(CurveTween(curve: curve)),
           );

           // Fade in
           final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
           final fadeAnimation = animation.drive(
             fadeTween.chain(CurveTween(curve: curve)),
           );

           return ScaleTransition(
             scale: scaleAnimation,
             child: FadeTransition(opacity: fadeAnimation, child: child),
           );
         },
       );
}

/// Helper extension to easily push pages with custom transitions
extension NavigatorExtensions on NavigatorState {
  /// Push a new page with slide and fade transition
  Future<T?> pushWithSlide<T>(WidgetBuilder builder) {
    return push<T>(SlidePageRoute<T>(builder: builder));
  }

  /// Push a dialog with scale and fade transition
  Future<T?> pushDialogWithScale<T>(WidgetBuilder builder) {
    return push<T>(ScaleDialogRoute<T>(builder: builder));
  }
}
