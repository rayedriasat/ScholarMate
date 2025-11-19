/// Real-time cursor indicator widget
import 'package:flutter/material.dart';
import '../models/collaboration.dart';

class CollaborationCursor extends StatelessWidget {
  final SessionParticipant participant;
  final Size pdfViewSize;
  
  const CollaborationCursor({
    super.key,
    required this.participant,
    required this.pdfViewSize,
  });
  
  @override
  Widget build(BuildContext context) {
    final cursor = participant.cursorPosition;
    if (cursor == null) return const SizedBox.shrink();
    
    // Convert normalized position to screen coordinates
    final x = cursor.x * pdfViewSize.width;
    final y = cursor.y * pdfViewSize.height;
    
    return Positioned(
      left: x,
      top: y,
      child: _CursorPointer(
        color: participant.userColor,
        userName: participant.userName,
      ),
    );
  }
}

class _CursorPointer extends StatelessWidget {
  final Color color;
  final String userName;
  
  const _CursorPointer({
    required this.color,
    required this.userName,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cursor pointer
        CustomPaint(
          size: const Size(16, 20),
          painter: _CursorPainter(color),
        ),
        const SizedBox(height: 2),
        // User name label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CursorPainter extends CustomPainter {
  final Color color;
  
  _CursorPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width * 0.3, size.height * 0.7)
      ..lineTo(size.width * 0.5, size.height * 0.9)
      ..lineTo(size.width * 0.7, size.height * 0.6)
      ..lineTo(size.width, size.height * 0.7)
      ..close();
    
    canvas.drawPath(path, paint);
    
    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawPath(path, borderPaint);
  }
  
  @override
  bool shouldRepaint(_CursorPainter oldDelegate) => oldDelegate.color != color;
}
