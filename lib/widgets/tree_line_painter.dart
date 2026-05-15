// Add this custom painter for tree lines

import 'package:flutter/cupertino.dart';

class TreeLinePainter extends CustomPainter {
  final Color color;
  final int level;

  TreeLinePainter({required this.color, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Draw vertical line
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width / 2, size.height);

    // Draw horizontal line to the right
    path.moveTo(size.width / 2, size.height / 2);
    path.lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}