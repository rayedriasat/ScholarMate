import 'package:flutter/material.dart';
import 'package:glassmorphic_ui_kit/glassmorphic_ui_kit.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';

/// Custom glass card wrapper component with configurable opacity and blur
/// Wraps the glassmorphic_ui_kit GlassContainer with app-specific styling
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool enableHover;
  final double? blur;
  final double? opacity;
  final BorderRadius? borderRadius;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.enableHover = true,
    this.blur,
    this.opacity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glassTheme;

    Widget card = GlassContainer(
      width: width,
      height: height,
      blur: blur ?? glassTheme.blur,
      opacity: opacity ?? glassTheme.opacity,
      borderRadius: borderRadius ?? glassTheme.borderRadius,
      gradient: glassTheme.gradient,
      border: Border.all(
        color: glassTheme.borderColor,
        width: glassTheme.borderWidth,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(DesignTokens.space4),
        child: child,
      ),
    );

    if (enableHover) {
      card = _HoverEffect(child: card);
    }

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? glassTheme.borderRadius,
        child: card,
      );
    }

    return card;
  }
}

/// Internal hover effect widget for glass cards
class _HoverEffect extends StatefulWidget {
  final Widget child;

  const _HoverEffect({required this.child});

  @override
  State<_HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<_HoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: DesignTokens.hoverDuration,
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _isHovered ? 0.9 : 1.0,
          duration: DesignTokens.hoverDuration,
          child: widget.child,
        ),
      ),
    );
  }
}
