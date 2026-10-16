import 'dart:math';

import 'package:flutter/material.dart';

/// Uses the board's finite completion animation without an additional ticker.
class BoardWinCelebration extends StatefulWidget {
  const BoardWinCelebration({
    super.key,
    required this.progress,
    required this.stars,
    this.seed,
  });
  final double progress;
  final int stars;
  final int? seed;
  @override
  State<BoardWinCelebration> createState() => _BoardWinCelebrationState();
}

class _BoardWinCelebrationState extends State<BoardWinCelebration> {
  late final random = Random(widget.seed);
  late final emoji = ['😄', '🥳', '🤩', '😊', '😎', '🙌'][random.nextInt(6)];
  late final label = () {
    final labels = [
      'Well done!',
      'Amazing!',
      'Way to go!',
      'Brilliant!',
      if (widget.stars == 3) 'Perfect!',
    ];
    return labels[random.nextInt(labels.length)];
  }();
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final t = widget.progress.clamp(0.0, 1.0);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!reduced)
            RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('board-crackers'),
                painter: _BoardCrackers(t),
              ),
            ),
          Center(
            child: Transform.scale(
              scale: reduced
                  ? 1
                  : .8 +
                        .2 *
                            Curves.easeOutBack.transform(
                              (t / .35).clamp(0.0, 1.0),
                            ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF2FFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x18051B3D), blurRadius: 18),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        emoji,
                        style: const TextStyle(
                          fontSize: 48,
                          fontFamilyFallback: [
                            'Noto Color Emoji',
                            'Apple Color Emoji',
                            'Segoe UI Emoji',
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      key: const ValueKey('board-win-label'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF064681),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Four small radial bursts, driven by the two-second board celebration.
/// No paper particles, extra controller, repeating animation or save/ad work.
class _BoardCrackers extends CustomPainter {
  _BoardCrackers(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    const centers = [
      Offset(.16, .33),
      Offset(.84, .34),
      Offset(.18, .67),
      Offset(.82, .66),
    ];
    const colors = [
      Color(0xFFFFAA22),
      Color(0xFF168FDF),
      Color(0xFFE64B91),
      Color(0xFF16AB91),
    ];
    final radius = min(size.width * .19, size.height * .15);
    final stroke = Paint()..strokeCap = StrokeCap.round;
    for (var burst = 0; burst < centers.length; burst++) {
      final age = progress - burst * .075;
      if (age <= 0 || age >= .76) continue;
      final t = age / .76;
      final origin = Offset(
        centers[burst].dx * size.width,
        centers[burst].dy * size.height,
      );
      final spread = Curves.easeOutCubic.transform(t);
      final fade = pow(1 - t, 1.3).toDouble();
      final tint = colors[burst];
      // A tiny flash at ignition, then bright streaks with trailing embers.
      canvas.drawCircle(
        origin,
        8 * (1 - t),
        Paint()..color = tint.withValues(alpha: fade * .25),
      );
      for (var ray = 0; ray < 22; ray++) {
        final angle = ray * 2 * pi / 22 + burst * .4;
        final direction = Offset(cos(angle), sin(angle));
        final distance = radius * spread * (.72 + (ray % 4) * .09);
        final gravity = Offset(0, radius * .23 * t * t);
        final tip = origin + direction * distance + gravity;
        final tail = tip - direction * (3 + 12 * (1 - t));
        final color = ray % 3 == 0 ? const Color(0xFFFFB52E) : tint;
        canvas.drawLine(
          tail,
          tip,
          stroke
            ..color = color.withValues(alpha: fade * .17)
            ..strokeWidth = 5,
        );
        canvas.drawLine(
          tail,
          tip,
          stroke
            ..color = color.withValues(alpha: fade)
            ..strokeWidth = 1.8,
        );
        if (ray.isEven) {
          canvas.drawCircle(
            tip,
            1.5 * (1 - t * .5),
            Paint()..color = color.withValues(alpha: fade),
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoardCrackers oldDelegate) =>
      oldDelegate.progress != progress;
}
