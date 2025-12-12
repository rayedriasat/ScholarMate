import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget? child;

  const AnimatedBackground({super.key, this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.background
        : const Color(0xFFFAFAFA); // Soft white/gray

    return Stack(
      children: [
        // Base background
        Container(color: backgroundColor),

        // Animated Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: BackgroundPainter(
                animationValue: _controller.value,
                primary: isDark
                    ? AppColors.primary
                    : const Color(0xFF3B82F6), // Brighter Blue 500
                secondary: isDark
                    ? AppColors.secondary
                    : const Color(0xFFEC4899), // Brighter Pink 500
                accent: isDark
                    ? AppColors.accent
                    : const Color(0xFF14B8A6), // Brighter Teal 500
                isDark: isDark,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Content
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color primary;
  final Color secondary;
  final Color accent;
  final bool isDark;

  BackgroundPainter({
    required this.animationValue,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Use MaskFilter for blur effect instead of expensive BackdropFilter
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    final alphaMultiplier = isDark
        ? 1.0
        : 0.8; // More visible colors for light mode

    // Orb 1 (Primary) - Top Left
    paint.color = primary.withValues(alpha: 0.3 * alphaMultiplier);
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + (sin(animationValue * 2 * pi) * 50),
        size.height * 0.2 + (cos(animationValue * 2 * pi) * 30),
      ),
      200,
      paint,
    );

    // Orb 2 (Secondary) - Bottom Right
    paint.color = secondary.withValues(alpha: 0.2 * alphaMultiplier);
    canvas.drawCircle(
      Offset(
        size.width * 0.8 - (cos(animationValue * 2 * pi) * 50),
        size.height * 0.8 - (sin(animationValue * 2 * pi) * 30),
      ),
      250,
      paint,
    );

    // Orb 3 (Accent) - Center/Moving
    paint.color = accent.withValues(alpha: 0.15 * alphaMultiplier);
    canvas.drawCircle(
      Offset(
        size.width * 0.5 + (cos(animationValue * pi) * 100),
        size.height * 0.5 + (sin(animationValue * pi) * 50),
      ),
      150,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}
