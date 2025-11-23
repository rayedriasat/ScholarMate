import 'package:flutter/material.dart';
import 'package:glassmorphic_ui_kit/glassmorphic_ui_kit.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';

/// Glass dialog component with animated backdrop blur
class GlassDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;
  final EdgeInsets? actionsPadding;
  final double? width;
  final double? height;
  final bool barrierDismissible;

  const GlassDialog({
    super.key,
    this.title,
    this.titleWidget,
    required this.content,
    this.actions,
    this.contentPadding,
    this.actionsPadding,
    this.width,
    this.height,
    this.barrierDismissible = true,
  }) : assert(
         title == null || titleWidget == null,
         'Cannot provide both title and titleWidget',
       );

  /// Show the glass dialog
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    required Widget content,
    List<Widget>? actions,
    EdgeInsets? contentPadding,
    EdgeInsets? actionsPadding,
    double? width,
    double? height,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => GlassDialog(
        title: title,
        titleWidget: titleWidget,
        content: content,
        actions: actions,
        contentPadding: contentPadding,
        actionsPadding: actionsPadding,
        width: width,
        height: height,
        barrierDismissible: barrierDismissible,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glassTheme;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width ?? 500,
          maxHeight: height ?? MediaQuery.of(context).size.height * 0.8,
        ),
        child: GlassContainer(
          blur: glassTheme.blur * 1.5, // Stronger blur for dialogs
          opacity: glassTheme.opacity * 1.2,
          borderRadius: const BorderRadius.all(
            Radius.circular(DesignTokens.radiusLarge),
          ),
          gradient: glassTheme.gradient,
          border: Border.all(
            color: glassTheme.borderColor,
            width: glassTheme.borderWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title section
              if (title != null || titleWidget != null)
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.space6),
                  child:
                      titleWidget ??
                      Text(
                        title!,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: DesignTokens.semiBold,
                        ),
                      ),
                ),

              // Divider
              if (title != null || titleWidget != null)
                Divider(height: 1, thickness: 1, color: glassTheme.borderColor),

              // Content section
              Flexible(
                child: SingleChildScrollView(
                  padding:
                      contentPadding ??
                      const EdgeInsets.all(DesignTokens.space6),
                  child: content,
                ),
              ),

              // Actions section
              if (actions != null && actions!.isNotEmpty) ...[
                Divider(height: 1, thickness: 1, color: glassTheme.borderColor),
                Padding(
                  padding:
                      actionsPadding ??
                      const EdgeInsets.all(DesignTokens.space4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (int i = 0; i < actions!.length; i++) ...[
                        if (i > 0) const SizedBox(width: DesignTokens.space2),
                        actions![i],
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated glass dialog that scales in
class AnimatedGlassDialog extends StatefulWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;
  final EdgeInsets? actionsPadding;
  final double? width;
  final double? height;

  const AnimatedGlassDialog({
    super.key,
    this.title,
    this.titleWidget,
    required this.content,
    this.actions,
    this.contentPadding,
    this.actionsPadding,
    this.width,
    this.height,
  });

  /// Show the animated glass dialog
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    required Widget content,
    List<Widget>? actions,
    EdgeInsets? contentPadding,
    EdgeInsets? actionsPadding,
    double? width,
    double? height,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: DesignTokens.dialogDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AnimatedGlassDialog(
          title: title,
          titleWidget: titleWidget,
          content: content,
          actions: actions,
          contentPadding: contentPadding,
          actionsPadding: actionsPadding,
          width: width,
          height: height,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  State<AnimatedGlassDialog> createState() => _AnimatedGlassDialogState();
}

class _AnimatedGlassDialogState extends State<AnimatedGlassDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DesignTokens.dialogDuration,
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GlassDialog(
          title: widget.title,
          titleWidget: widget.titleWidget,
          content: widget.content,
          actions: widget.actions,
          contentPadding: widget.contentPadding,
          actionsPadding: widget.actionsPadding,
          width: widget.width,
          height: widget.height,
        ),
      ),
    );
  }
}
