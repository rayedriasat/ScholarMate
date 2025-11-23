import 'package:flutter/material.dart';
import 'package:glassmorphic_ui_kit/glassmorphic_ui_kit.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';

/// Glass button style variants
enum GlassButtonVariant {
  elevated, // Default glass with shadow
  outlined, // Glass with prominent border
  filled, // Glass with accent color fill
}

/// Glass button component with hover and pressed states
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = GlassButtonVariant.elevated,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
  });

  /// Factory constructor for elevated variant
  factory GlassButton.elevated({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    EdgeInsets? padding,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return GlassButton(
      key: key,
      variant: GlassButtonVariant.elevated,
      onPressed: onPressed,
      padding: padding,
      width: width,
      height: height,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Factory constructor for outlined variant
  factory GlassButton.outlined({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    EdgeInsets? padding,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return GlassButton(
      key: key,
      variant: GlassButtonVariant.outlined,
      onPressed: onPressed,
      padding: padding,
      width: width,
      height: height,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Factory constructor for filled variant
  factory GlassButton.filled({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    EdgeInsets? padding,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return GlassButton(
      key: key,
      variant: GlassButtonVariant.filled,
      onPressed: onPressed,
      padding: padding,
      width: width,
      height: height,
      borderRadius: borderRadius,
      child: child,
    );
  }

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glassTheme;
    final accentColor = context.watchThemeProvider.accentColor;
    final isEnabled = widget.onPressed != null;

    // Calculate opacity based on state
    double opacity = glassTheme.opacity;
    if (!isEnabled) {
      opacity *= 0.5;
    } else if (_isPressed) {
      opacity *= 1.5;
    } else if (_isHovered) {
      opacity *= 1.2;
    }

    // Calculate border based on variant
    Border border;
    switch (widget.variant) {
      case GlassButtonVariant.elevated:
        border = Border.all(
          color: glassTheme.borderColor,
          width: glassTheme.borderWidth,
        );
        break;
      case GlassButtonVariant.outlined:
        border = Border.all(
          color: isEnabled
              ? accentColor.withValues(alpha: 0.5)
              : glassTheme.borderColor,
          width: 2.0,
        );
        break;
      case GlassButtonVariant.filled:
        border = Border.all(
          color: isEnabled
              ? accentColor.withValues(alpha: 0.3)
              : glassTheme.borderColor,
          width: glassTheme.borderWidth,
        );
        break;
    }

    // Calculate gradient based on variant
    LinearGradient gradient;
    if (widget.variant == GlassButtonVariant.filled && isEnabled) {
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withValues(alpha: 0.3),
          accentColor.withValues(alpha: 0.2),
        ],
      );
    } else {
      gradient = glassTheme.gradient;
    }

    final borderRadius =
        widget.borderRadius ??
        const BorderRadius.all(Radius.circular(DesignTokens.radiusMedium));

    return MouseRegion(
      onEnter: isEnabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: isEnabled ? (_) => setState(() => _isHovered = false) : null,
      cursor: isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled
            ? () => setState(() => _isPressed = false)
            : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0),
          duration: DesignTokens.hoverDuration,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: isEnabled ? 1.0 : 0.6,
            duration: DesignTokens.hoverDuration,
            child: GlassContainer(
              width: widget.width,
              height: widget.height,
              blur: glassTheme.blur,
              opacity: opacity,
              borderRadius: borderRadius,
              gradient: gradient,
              border: border,
              child: Padding(
                padding:
                    widget.padding ??
                    const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space4,
                      vertical: DesignTokens.space3,
                    ),
                child: Center(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: isEnabled
                          ? (widget.variant == GlassButtonVariant.filled
                                ? accentColor
                                : Theme.of(context).textTheme.bodyLarge?.color)
                          : Theme.of(context).disabledColor,
                      fontWeight: DesignTokens.medium,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
