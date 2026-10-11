import 'dart:math';

import 'package:flutter/material.dart';

/// Two independently moving, mirrored hands; no emoji or animated image asset.
class ClappingHands extends StatelessWidget {
  const ClappingHands({super.key, required this.seconds});
  final double seconds;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 72,
      height: 38,
      child: CustomPaint(painter: ClappingHandsPainter(seconds)),
    ),
  );
}

class ClappingHandsPainter extends CustomPainter {
  ClappingHandsPainter(this.seconds);
  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final opening = (1 + cos(max(0.0, seconds) * 4 * pi)) / 2;
    canvas.save();
    canvas.scale(size.width / 72, size.height / 38);
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(36 + side * (13 + 9 * opening), 22);
      canvas.scale(-side, 1);
      canvas.rotate(.32 + .12 * opening);
      final hand = Path()
        ..moveTo(-7, 13)
        ..lineTo(-10, 0)
        ..lineTo(-11, -10)
        ..cubicTo(-11, -13, -7, -13, -7, -10)
        ..lineTo(-6, -4)
        ..lineTo(-6, -16)
        ..cubicTo(-6, -19, -2, -19, -2, -16)
        ..lineTo(-2, -5)
        ..lineTo(-1, -18)
        ..cubicTo(-1, -21, 3, -21, 3, -18)
        ..lineTo(3, -5)
        ..lineTo(4, -15)
        ..cubicTo(4, -18, 8, -18, 8, -15)
        ..lineTo(8, 0)
        ..lineTo(10, -3)
        ..cubicTo(13, -6, 16, -3, 13, 1)
        ..lineTo(9, 8)
        ..quadraticBezierTo(7, 11, 6, 13)
        ..close();
      canvas.drawShadow(hand, const Color(0x77071B33), 1.5, false);
      canvas.drawPath(
        hand,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF3D9), Color(0xFFE9B57D)],
          ).createShader(const Rect.fromLTWH(-11, -20, 26, 35)),
      );
      canvas.drawPath(
        hand,
        Paint()
          ..color = const Color(0xFF805937)
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = .8,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-4, 3)
          ..quadraticBezierTo(1, 0, 6, 3),
        Paint()
          ..color = const Color(0xFFBC885B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-8, 11, 15, 5),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFFF7FAFF),
      );
      canvas.drawLine(
        const Offset(-7, 14),
        const Offset(6, 14),
        Paint()
          ..color = const Color(0xFF178DDD)
          ..strokeWidth = 1.3,
      );
      canvas.restore();
    }
    // A tiny impact glint only when the palms meet.
    if (opening < .12) {
      final ink = Paint()
        ..color = const Color(0xFFFFE7A5).withValues(alpha: 1 - opening / .12)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(36, 1), const Offset(36, 4), ink);
      canvas.drawLine(const Offset(30, 2), const Offset(32, 5), ink);
      canvas.drawLine(const Offset(42, 2), const Offset(40, 5), ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ClappingHandsPainter oldDelegate) =>
      oldDelegate.seconds != seconds;
}
