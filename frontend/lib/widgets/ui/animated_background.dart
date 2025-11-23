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
    return Stack(
      children: [
        // Base background
        Container(color: AppColors.background),

        // Animated Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: BackgroundPainter(
                animationValue: _controller.value,
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                accent: AppColors.accent,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Blur overlay to smooth out the orbs
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(color: Colors.transparent),
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

  BackgroundPainter({
    required this.animationValue,
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Orb 1 (Primary) - Top Left
    paint.color = primary.withValues(alpha: 0.3);
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + (sin(animationValue * 2 * pi) * 50),
        size.height * 0.2 + (cos(animationValue * 2 * pi) * 30),
      ),
      200,
      paint,
    );

    // Orb 2 (Secondary) - Bottom Right
    paint.color = secondary.withValues(alpha: 0.2);
    canvas.drawCircle(
      Offset(
        size.width * 0.8 - (cos(animationValue * 2 * pi) * 50),
        size.height * 0.8 - (sin(animationValue * 2 * pi) * 30),
      ),
      250,
      paint,
    );

    // Orb 3 (Accent) - Center/Moving
    paint.color = accent.withValues(alpha: 0.15);
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
    return oldDelegate.animationValue != animationValue;
  }
}
