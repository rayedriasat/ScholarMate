import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white
        : Theme.of(context).colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? baseColor.withValues(alpha: opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border ?? Border.all(color: borderColor, width: 1.0),
      ),
      child: child,
    );

    if (blur > 0) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: content,
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}
