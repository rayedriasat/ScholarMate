import 'package:flutter/material.dart';
import '../../utils/animation_utils.dart';

/// A widget that applies hover effects with scale and opacity animations
///
/// This widget wraps its child and applies a subtle scale transform (1.02x by default)
/// and opacity change when the mouse hovers over it. The animation respects the
/// user's reduced motion accessibility preferences.
///
/// Example:
/// ```dart
/// HoverEffect(
///   child: Container(
///     padding: EdgeInsets.all(16),
///     child: Text('Hover over me'),
///   ),
/// )
/// ```
class HoverEffect extends StatefulWidget {
  /// The widget to apply hover effects to
  final Widget child;

  /// The scale factor to apply on hover (default: 1.02)
  final double scale;

  /// The opacity to apply on hover (default: 0.9)
  final double opacity;

  /// The duration of the hover animation (default: 200ms)
  final Duration duration;

  /// The animation curve (default: Curves.easeOut)
  final Curve curve;

  /// Whether hover effects are enabled (default: true)
  /// Set to false to disable hover effects without removing the widget
  final bool enabled;

  const HoverEffect({
    Key? key,
    required this.child,
    this.scale = AnimationConstants.hoverScale,
    this.opacity = AnimationConstants.hoverOpacity,
    this.duration = AnimationConstants.hoverDuration,
    this.curve = AnimationConstants.defaultCurve,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // If hover effects are disabled, return child directly
    if (!widget.enabled) {
      return widget.child;
    }

    // Get animation duration and curve based on reduced motion preference
    final duration = AnimationConstants.getAnimationDuration(
      context,
      widget.duration,
    );
    final curve = AnimationConstants.getAnimationCurve(context, widget.curve);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? widget.scale : 1.0,
        duration: duration,
        curve: curve,
        child: AnimatedOpacity(
          opacity: _isHovered ? widget.opacity : 1.0,
          duration: duration,
          curve: curve,
          child: widget.child,
        ),
      ),
    );
  }
}
