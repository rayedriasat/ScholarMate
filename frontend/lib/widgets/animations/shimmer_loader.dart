import 'package:flutter/material.dart';
import '../../utils/animation_utils.dart';

/// A shimmer loading skeleton widget for displaying loading states
///
/// This widget creates a shimmer animation effect that moves across the child widget,
/// providing visual feedback during async operations. The animation respects the
/// user's reduced motion accessibility preferences.
///
/// Example:
/// ```dart
/// ShimmerLoader(
///   child: Container(
///     width: 200,
///     height: 20,
///     decoration: BoxDecoration(
///       color: Colors.grey[300],
///       borderRadius: BorderRadius.circular(4),
///     ),
///   ),
/// )
/// ```
class ShimmerLoader extends StatefulWidget {
  /// The widget to apply shimmer effect to (typically a placeholder)
  final Widget child;

  /// The duration of one shimmer cycle (default: 1500ms)
  final Duration duration;

  /// The base color of the shimmer gradient
  final Color? baseColor;

  /// The highlight color of the shimmer gradient
  final Color? highlightColor;

  /// Whether the shimmer animation is enabled (default: true)
  final bool enabled;

  const ShimmerLoader({
    Key? key,
    required this.child,
    this.duration = AnimationConstants.shimmerDuration,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(
      begin: AnimationConstants.shimmerBegin,
      end: AnimationConstants.shimmerEnd,
    ).animate(_controller);

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check for reduced motion preference
    final reducedMotion = AnimationConstants.isReducedMotionEnabled(context);

    // If reduced motion is enabled or shimmer is disabled, return child without animation
    if (reducedMotion || !widget.enabled) {
      return widget.child;
    }

    // Get colors from theme if not provided
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Pre-built shimmer skeleton widgets for common use cases

/// A shimmer skeleton for text lines
class ShimmerTextLine extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerTextLine({
    Key? key,
    this.width = double.infinity,
    this.height = 16.0,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// A shimmer skeleton for a card
class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerCard({
    Key? key,
    this.width = double.infinity,
    this.height = 200.0,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// A shimmer skeleton for a circular avatar
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({Key? key, this.size = 40.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// A shimmer skeleton for a file card with thumbnail, title, and metadata
class ShimmerFileCard extends StatelessWidget {
  final double width;

  const ShimmerFileCard({Key? key, this.width = double.infinity})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ShimmerCard(
            width: width,
            height: 150,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 12),
          // Title
          const ShimmerTextLine(width: double.infinity, height: 18),
          const SizedBox(height: 8),
          // Metadata
          Row(
            children: const [
              ShimmerTextLine(width: 60, height: 14),
              SizedBox(width: 12),
              ShimmerTextLine(width: 80, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}
