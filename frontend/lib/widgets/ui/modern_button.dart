import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum ModernButtonVariant { primary, secondary, ghost, outline }

class ModernButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ModernButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;

  const ModernButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = ModernButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (widget.onPressed == null) return Colors.grey.withValues(alpha: 0.3);
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    switch (widget.variant) {
      case ModernButtonVariant.primary:
        return AppColors.primary;
      case ModernButtonVariant.secondary:
        return AppColors.secondary;
      case ModernButtonVariant.ghost:
        return _isHovered
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.transparent;
      case ModernButtonVariant.outline:
        return _isHovered
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (widget.onPressed == null) return Colors.grey;
    if (widget.textColor != null) return widget.textColor!;

    switch (widget.variant) {
      case ModernButtonVariant.primary:
      case ModernButtonVariant.secondary:
        return Colors.white;
      case ModernButtonVariant.ghost:
        return AppColors.textPrimary;
      case ModernButtonVariant.outline:
        return AppColors.primary;
    }
  }

  BoxBorder? _getBorder() {
    if (widget.variant == ModernButtonVariant.outline) {
      return Border.all(
        color: widget.onPressed == null ? Colors.grey : AppColors.primary,
        width: 1.5,
      );
    }
    return null;
  }

  List<BoxShadow> _getShadows() {
    if (widget.variant == ModernButtonVariant.primary &&
        widget.onPressed != null &&
        !_isHovered &&
        widget.backgroundColor == null) {
      return [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }
    if (widget.variant == ModernButtonVariant.secondary &&
        widget.onPressed != null &&
        !_isHovered &&
        widget.backgroundColor == null) {
      return [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height ?? 48,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              border: _getBorder(),
              boxShadow: _getShadows(),
              gradient:
                  widget.variant == ModernButtonVariant.primary &&
                      widget.onPressed != null &&
                      widget.backgroundColor == null
                  ? AppColors.primaryGradient
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getTextColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (widget.icon != null) ...[
                  Icon(widget.icon, color: _getTextColor(), size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: _getTextColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
