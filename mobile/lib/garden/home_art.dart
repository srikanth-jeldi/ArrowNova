import 'package:flutter/material.dart';

// Resolution-independent room and furnishings keep the download small.
class HomeRoomPainter extends CustomPainter {
  const HomeRoomPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 400);
    final p = Paint();
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 400),
      p..color = const Color(0xFFEDE3D3),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 235),
      p
        ..shader = const LinearGradient(
          colors: [Color(0xFFDFE9E4), Color(0xFF9AB6B6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(0, 0, 400, 235)),
    );
    p.shader = null;
    for (double x = 15; x < 400; x += 75) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 20, 60, 190),
          const Radius.circular(3),
        ),
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x5580A0A0),
      );
    }
    p.style = PaintingStyle.fill;
    canvas.drawRect(
      const Rect.fromLTWH(0, 231, 400, 169),
      p
        ..shader = const LinearGradient(
          colors: [Color(0xFFB88C62), Color(0xFFE1BD91)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(0, 231, 400, 169)),
    );
    p.shader = null;
    for (double x = -400; x < 800; x += 65) {
      canvas.drawLine(
        Offset(200 + (x - 200) * .35, 231),
        Offset(x, 400),
        p
          ..color = const Color(0x55826344)
          ..strokeWidth = 1,
      );
    }
    for (final y in [250.0, 280.0, 323.0, 380.0]) {
      canvas.drawLine(
        Offset(0, y),
        Offset(400, y),
        p..color = const Color(0x44826344),
      );
    }
    canvas.drawRect(
      const Rect.fromLTWH(0, 225, 400, 9),
      p..color = const Color(0xFFF9F1E3),
    );
    canvas.drawShadow(
      Path()..addRect(const Rect.fromLTWH(128, 42, 144, 134)),
      Colors.black,
      5,
      false,
    );
    canvas.drawRect(
      const Rect.fromLTWH(128, 42, 144, 134),
      p..color = const Color(0xFFFAF7EA),
    );
    canvas.drawRect(
      const Rect.fromLTWH(135, 49, 130, 120),
      p
        ..shader = const LinearGradient(
          colors: [Color(0xFF7CC8E2), Color(0xFFE6F6EF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(135, 49, 130, 120)),
    );
    p.shader = null;
    canvas.drawPath(
      Path()
        ..moveTo(135, 150)
        ..lineTo(165, 114)
        ..lineTo(191, 145)
        ..lineTo(227, 107)
        ..lineTo(265, 149)
        ..lineTo(265, 169)
        ..lineTo(135, 169)
        ..close(),
      p..color = const Color(0xFF90B7A0),
    );
    canvas.drawRect(
      const Rect.fromLTWH(197, 49, 6, 120),
      p..color = const Color(0xFFFFFBED),
    );
    canvas.drawRect(const Rect.fromLTWH(135, 108, 130, 5), p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(120, 174, 160, 7),
        const Radius.circular(2),
      ),
      p,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HomeRoomPainter oldDelegate) => false;
}

class HomeItemPainter extends CustomPainter {
  const HomeItemPainter(this.id);
  final String id;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final p = Paint();
    void rect(
      double x,
      double y,
      double w,
      double h,
      Color color, [
      double r = 2,
    ]) => canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      p..color = color,
    );
    const gold = Color(0xFFC9A459);
    const wood = Color(0xFF9D673D);
    switch (id) {
      case 'cream_sofa':
        rect(15, 74, 6, 16, wood);
        rect(79, 74, 6, 16, wood);
        rect(8, 31, 84, 47, const Color(0xFFCCBA9E), 10);
        rect(14, 34, 34, 30, const Color(0xFFF5E9D2), 7);
        rect(52, 34, 34, 30, const Color(0xFFF5E9D2), 7);
        rect(15, 63, 70, 13, const Color(0xFFE8D9BE), 5);
        rect(4, 49, 12, 29, const Color(0xFFE8D9BE), 5);
        rect(84, 49, 12, 29, const Color(0xFFE8D9BE), 5);
      case 'gallery':
        for (var n = 0; n < 3; n++) {
          canvas.save();
          canvas.translate(n * 32.0, n == 1 ? 15 : 23);
          const HomeItemPainter('painting').paint(canvas, const Size(36, 55));
          canvas.restore();
        }
      case 'curtains':
      case 'linen':
        final dark = id == 'linen'
            ? const Color(0xFFCFBDA0)
            : const Color(0xFF145A68);
        final light = id == 'linen'
            ? const Color(0xFFFFF4DB)
            : const Color(0xFF448D97);
        rect(3, 8, 94, 3, gold);
        for (final right in [false, true]) {
          canvas.save();
          if (right) {
            canvas.translate(100, 0);
            canvas.scale(-1, 1);
          }
          final cloth = Path()
            ..moveTo(7, 12)
            ..lineTo(36, 12)
            ..quadraticBezierTo(34, 43, 18, 58)
            ..lineTo(33, 88)
            ..quadraticBezierTo(20, 94, 6, 87)
            ..close();
          p.shader = LinearGradient(colors: [dark, light, dark, light, dark])
              .createShader(const Rect.fromLTWH(6, 12, 30, 80));
          canvas.drawPath(cloth, p);
          p.shader = null;
          rect(7, 56, 15, 3, gold);
          canvas.restore();
        }
      case 'royal_rug':
      case 'rug':
        canvas.drawOval(
          const Rect.fromLTWH(2, 40, 96, 47),
          p..color = const Color(0x33000000),
        );
        canvas.drawOval(const Rect.fromLTWH(2, 38, 96, 45), p..color = gold);
        canvas.drawOval(
          const Rect.fromLTWH(6, 41, 88, 39),
          p..color = const Color(0xFF24576B),
        );
        canvas.drawOval(
          const Rect.fromLTWH(13, 45, 74, 31),
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = gold,
        );
        p.style = PaintingStyle.fill;
        canvas.drawPath(
          Path()
            ..moveTo(50, 48)
            ..lineTo(72, 60)
            ..lineTo(50, 73)
            ..lineTo(28, 60)
            ..close(),
          p..color = const Color(0xFF79999C),
        );
        if (id == 'royal_rug') {
          for (double x = 15; x <= 85; x += 10) {
            canvas.drawCircle(Offset(x, 54), 1.8, p..color = gold);
            canvas.drawCircle(Offset(x, 68), 1.8, p);
          }
          canvas.drawOval(
            const Rect.fromLTWH(38, 52, 24, 17),
            p
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = gold,
          );
          p.style = PaintingStyle.fill;
        }
      case 'table':
        rect(17, 57, 6, 32, wood);
        rect(77, 57, 6, 32, wood);
        rect(12, 43, 76, 23, const Color(0xFF774A2F), 9);
        canvas.drawOval(
          const Rect.fromLTWH(9, 31, 82, 29),
          p..color = const Color(0xFFD1A77B),
        );
        canvas.drawOval(
          const Rect.fromLTWH(13, 34, 74, 23),
          p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = wood,
        );
        p.style = PaintingStyle.fill;
      case 'crystal_lamp':
      case 'lamp':
        canvas.drawOval(const Rect.fromLTWH(29, 84, 42, 9), p..color = gold);
        rect(48, 34, 4, 53, gold);
        canvas.drawPath(
          Path()
            ..moveTo(32, 8)
            ..lineTo(68, 8)
            ..lineTo(80, 40)
            ..quadraticBezierTo(50, 48, 20, 40)
            ..close(),
          p..color = const Color(0xFFFFE8BA),
        );
        canvas.drawOval(
          const Rect.fromLTWH(32, 5, 36, 7),
          p..color = const Color(0xFFF7F0D9),
        );
        rect(20, 39, 60, 2, gold);
        if (id == 'crystal_lamp') {
          for (double x = 25; x < 80; x += 10) {
            canvas.drawLine(
              Offset(x, 18),
              Offset(x, 38),
              p
                ..color = gold
                ..strokeWidth = 1,
            );
            canvas.drawPath(
              Path()
                ..moveTo(x, 40)
                ..lineTo(x + 3, 46)
                ..lineTo(x, 52)
                ..lineTo(x - 3, 46)
                ..close(),
              p..color = const Color(0xFFBCECF6),
            );
          }
        }
      case 'painting':
        rect(5, 15, 90, 65, gold);
        rect(10, 20, 80, 55, const Color(0xFFDEEBE8));
        canvas.drawCircle(
          const Offset(66, 34),
          9,
          p..color = const Color(0xFFEDC66B),
        );
        canvas.drawPath(
          Path()
            ..moveTo(10, 66)
            ..lineTo(33, 33)
            ..lineTo(57, 66)
            ..lineTo(74, 46)
            ..lineTo(90, 66)
            ..lineTo(90, 75)
            ..lineTo(10, 75)
            ..close(),
          p..color = const Color(0xFF447A83),
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HomeItemPainter oldDelegate) =>
      id != oldDelegate.id;
}
