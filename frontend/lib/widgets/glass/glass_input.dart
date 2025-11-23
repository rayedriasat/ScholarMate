import 'package:flutter/material.dart';
import 'package:glassmorphic_ui_kit/glassmorphic_ui_kit.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';

/// Glass text input field with focus states and floating labels
class GlassInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const GlassInput({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.textInputAction,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glassTheme;
    final accentColor = context.watchThemeProvider.accentColor;
    final theme = Theme.of(context);

    // Adjust opacity and border based on focus state
    final opacity = _isFocused ? glassTheme.opacity * 1.3 : glassTheme.opacity;
    final borderColor = _isFocused
        ? accentColor.withValues(alpha: 0.6)
        : (widget.errorText != null
              ? DesignTokens.error[500]!.withValues(alpha: 0.6)
              : glassTheme.borderColor);
    final borderWidth = _isFocused ? 2.0 : glassTheme.borderWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: DesignTokens.hoverDuration,
          curve: Curves.easeOut,
          child: GlassContainer(
            blur: glassTheme.blur,
            opacity: opacity,
            borderRadius: const BorderRadius.all(
              Radius.circular(DesignTokens.radiusMedium),
            ),
            gradient: glassTheme.gradient,
            border: Border.all(color: borderColor, width: borderWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space3,
                vertical: DesignTokens.space2,
              ),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    widget.prefixIcon!,
                    const SizedBox(width: DesignTokens.space2),
                  ],
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      keyboardType: widget.keyboardType,
                      obscureText: widget.obscureText,
                      maxLines: widget.maxLines,
                      minLines: widget.minLines,
                      onChanged: widget.onChanged,
                      onEditingComplete: widget.onEditingComplete,
                      onSubmitted: widget.onSubmitted,
                      enabled: widget.enabled,
                      readOnly: widget.readOnly,
                      textInputAction: widget.textInputAction,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        labelText: widget.labelText,
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        labelStyle: TextStyle(
                          color: _isFocused
                              ? accentColor
                              : theme.textTheme.bodyMedium?.color?.withValues(
                                  alpha: 0.7,
                                ),
                          fontSize: 14,
                        ),
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 14,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                  ),
                  if (widget.suffixIcon != null) ...[
                    const SizedBox(width: DesignTokens.space2),
                    widget.suffixIcon!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (widget.helperText != null || widget.errorText != null) ...[
          const SizedBox(height: DesignTokens.space1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space3,
            ),
            child: Text(
              widget.errorText ?? widget.helperText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: widget.errorText != null
                    ? DesignTokens.error[500]
                    : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
