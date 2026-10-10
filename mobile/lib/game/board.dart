import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'puzzle.dart';

class ArrowBoard extends StatelessWidget {
  const ArrowBoard({
    super.key,
    required this.game,
    required this.onTap,
    this.activeId,
    this.blocked = false,
    this.progress = 0,
    this.showGuide = false,
    this.celebration = 0,
  });
  final GameSession game;
  final ValueChanged<int?> onTap;
  final int? activeId;
  final bool blocked;
  final double progress;
  final bool showGuide;
  final double celebration;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      final geometry = BoardGeometry(game.puzzle, size);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (event) =>
            onTap(geometry.hit(event.localPosition, game.removed)),
        child: Stack(
          children: [
            CustomPaint(
              size: size,
              painter: ArrowPainter(
                game: game,
                geometry: geometry,
                activeId: activeId,
                blocked: blocked,
                progress: progress,
                reducedMotion: MediaQuery.disableAnimationsOf(context),
                onTap: onTap,
              ),
            ),
            if (celebration > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey('board-golden-wave'),
                    painter: GoldenWavePainter(celebration),
                  ),
                ),
              ),
            if (showGuide && game.hinted != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: TutorialHand(
                    key: ValueKey(game.hinted),
                    target: geometry.point(
                      game.puzzle.arrows
                          .firstWhere((a) => a.id == game.hinted)
                          .head,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class BoardGeometry {
  BoardGeometry(this.puzzle, this.size)
    : step = min(
        size.width / (puzzle.width + 1),
        size.height / (puzzle.height + 1),
      );
  final Puzzle puzzle;
  final Size size;
  final double step;
  Offset point(Cell c) => Offset(
    (size.width - (puzzle.width - 1) * step) / 2 + c.x * step,
    (size.height - (puzzle.height - 1) * step) / 2 + c.y * step,
  );

  int? hit(Offset position, Set<int> removed) {
    // A forgiving halo around the rendered path. Nearest geometry wins even
    // when halos overlap, so dense boards still select the intended arrow.
    var nearest = max(10.0, min(18.0, step * .55));
    int? selected;
    for (final arrow in puzzle.arrows) {
      if (removed.contains(arrow.id)) continue;
      final head = point(arrow.head);
      final direction = Offset(
        arrow.direction.x.toDouble(),
        arrow.direction.y.toDouble(),
      );
      final normal = Offset(-direction.dy, direction.dx);
      final tip = head + direction * step * .38;
      final shoulder = head - direction * step * .16;
      final headPath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          (shoulder + normal * step * .34).dx,
          (shoulder + normal * step * .34).dy,
        )
        ..lineTo(
          (shoulder - normal * step * .34).dx,
          (shoulder - normal * step * .34).dy,
        )
        ..close();
      if (headPath.contains(position)) return arrow.id;
      for (var i = 1; i < arrow.cells.length; i++) {
        final a = point(arrow.cells[i - 1]);
        final b = i == arrow.cells.length - 1 ? tip : point(arrow.cells[i]);
        final vector = b - a;
        final projection =
            ((position - a).dx * vector.dx + (position - a).dy * vector.dy) /
            vector.distanceSquared;
        final distance =
            (position - (a + vector * projection.clamp(0, 1))).distance;
        if (distance < nearest) {
          nearest = distance;
          selected = arrow.id;
        }
      }
    }
    return selected;
  }
}

class ArrowPainter extends CustomPainter {
  ArrowPainter({
    required this.game,
    required this.geometry,
    required this.onTap,
    this.activeId,
    this.blocked = false,
    this.progress = 0,
    this.reducedMotion = false,
  });
  final GameSession game;
  final BoardGeometry geometry;
  final int? activeId;
  final bool blocked;
  final double progress;
  final ValueChanged<int?> onTap;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    for (final arrow in game.puzzle.arrows) {
      if (game.removed.contains(arrow.id) && arrow.id != activeId) continue;
      canvas.save();
      final isError = arrow.id == activeId && blocked;
      if (isError && !reducedMotion) {
        final direction = arrow.direction;
        final bounce =
            sin(progress * pi * 2) * geometry.step * .14 * (1 - progress);
        canvas.translate(direction.x * bounce, direction.y * bounce);
      }
      final path = Path()
        ..moveTo(
          geometry.point(arrow.cells.first).dx,
          geometry.point(arrow.cells.first).dy,
        );
      for (final cell in arrow.cells.skip(1)) {
        final p = geometry.point(cell);
        path.lineTo(p.dx, p.dy);
      }
      var visible = path;
      var head = geometry.point(arrow.head);
      final dir = Offset(
        arrow.direction.x.toDouble(),
        arrow.direction.y.toDouble(),
      );
      if (arrow.id == activeId && !blocked) {
        final originalLength = path.computeMetrics().first.length;
        final travel =
            Curves.easeInCubic.transform(reducedMotion ? 1 : progress) *
            (originalLength + max(size.width, size.height) * 1.3);
        head += dir * travel;
        path.lineTo(head.dx, head.dy);
        visible = path.computeMetrics().first.extractPath(
          travel,
          originalLength + travel,
        );
      }
      if (arrow.id == activeId && !blocked && !reducedMotion && progress > 0) {
        final metric = path.computeMetrics().first;
        final length = metric.length;
        final tail = max(0.0, length - pathLength(arrow) - geometry.step * 3);
        final trail = metric.extractPath(
          tail,
          min(length, tail + geometry.step * 5),
        );
        canvas.drawPath(
          trail,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = geometry.step * .32
            ..color = const Color(0xFF42DFFF)
                .withValues(alpha: sin(progress * pi) * .45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
      final hint = game.hinted == arrow.id;
      final width = geometry.step * .18;
      final depth = (geometry.step * .07).clamp(.5, 1.4);
      final dark = isError
          ? const Color(0xFF972437)
          : hint
          ? const Color(0xFF916114)
          : const Color(0xFF064681);
      final light = isError
          ? const Color(0xFFFF8588)
          : hint
          ? const Color(0xFFFFE3A0)
          : const Color(0xFF76E7FF);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.save();
      canvas.translate(depth * .65, depth * 1.5);
      canvas.drawPath(
        visible,
        stroke
          ..color = const Color(0x40042544)
          ..strokeWidth = width + geometry.step * .04
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth * .8),
      );
      canvas.restore();
      stroke.maskFilter = null;
      canvas.drawPath(
        visible,
        stroke
          ..color = dark
          ..strokeWidth = width + geometry.step * .065,
      );
      canvas.drawPath(
        visible,
        stroke
          ..shader = LinearGradient(
            colors: [
              light,
              hint ? const Color(0xFFE0AE42) : const Color(0xFF098DEF),
              dark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(visible.getBounds().inflate(width))
          ..strokeWidth = width,
      );
      stroke.shader = null;
      canvas.save();
      canvas.translate(-depth * .35, -depth * .5);
      canvas.drawPath(
        visible,
        stroke
          ..color = light.withValues(alpha: .9)
          ..strokeWidth = max(.4, width * .22),
      );
      canvas.restore();
      final normal = Offset(-dir.dy, dir.dx);
      final tip = head + dir * geometry.step * .38;
      final shoulder = head - dir * geometry.step * .16;
      final neck = head - dir * geometry.step * .29;
      final wing = normal * geometry.step * .34;
      final halfShaft = normal * width * .5;
      final triangle = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo((shoulder + wing).dx, (shoulder + wing).dy)
        ..lineTo((shoulder + halfShaft).dx, (shoulder + halfShaft).dy)
        ..lineTo((neck + halfShaft).dx, (neck + halfShaft).dy)
        ..lineTo((neck - halfShaft).dx, (neck - halfShaft).dy)
        ..lineTo((shoulder - halfShaft).dx, (shoulder - halfShaft).dy)
        ..lineTo((shoulder - wing).dx, (shoulder - wing).dy)
        ..close();
      // Contrasting, solid arrowhead makes direction legible at board scale.
      // Green indicates the head, not whether the move is unblocked.
      final headColor = isError
          ? const Color(0xFFE63950)
          : hint
          ? const Color(0xFFFFC84A)
          : const Color(0xFF10B76A);
      final headOutline = isError
          ? const Color(0xFF78172A)
          : hint
          ? const Color(0xFF76520A)
          : const Color(0xFF064D36);
      canvas.drawShadow(triangle, const Color(0x50062C51), depth, false);
      canvas.drawPath(triangle, Paint()..color = headColor);
      canvas.drawPath(
        triangle,
        Paint()
          ..color = headOutline
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = max(.7, geometry.step * .045),
      );
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo((shoulder + wing).dx, (shoulder + wing).dy)
          ..lineTo(shoulder.dx, shoulder.dy)
          ..close(),
        Paint()..color = const Color(0x50FFFFFF),
      );
      canvas.restore();
      if (isError && !reducedMotion) {
        final contact = blockerContact(arrow);
        if (contact != null) {
          canvas.drawCircle(
            geometry.point(contact),
            geometry.step * (.3 + progress * .65),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = const Color(0xFFF34F6C)
                  .withValues(alpha: sin(progress * pi) * .85),
          );
        }
      }
    }
  }

  double pathLength(ArrowPath arrow) =>
      (arrow.cells.length - 1) * geometry.step;

  Cell? blockerContact(ArrowPath arrow) {
    final occupied = <Cell>{
      for (final other in game.puzzle.arrows)
        if (other.id != arrow.id && !game.removed.contains(other.id))
          ...other.cells,
    };
    var x = arrow.head.x + arrow.direction.x;
    var y = arrow.head.y + arrow.direction.y;
    while (x >= 0 &&
        y >= 0 &&
        x < game.puzzle.width &&
        y < game.puzzle.height) {
      final cell = Cell(x, y);
      if (occupied.contains(cell)) return cell;
      x += arrow.direction.x;
      y += arrow.direction.y;
    }
    return null;
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final arrow in game.puzzle.arrows)
          if (!game.removed.contains(arrow.id))
            CustomPainterSemantics(
              rect: Rect.fromCenter(
                center: geometry.point(arrow.head),
                width: geometry.step * .8,
                height: geometry.step * .8,
              ),
              properties: SemanticsProperties(
                label: 'Arrow ${arrow.id + 1}',
                button: true,
                textDirection: TextDirection.ltr,
                onTap: () => onTap(arrow.id),
              ),
            ),
      ];
  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) => true;
  @override
  bool shouldRebuildSemantics(covariant ArrowPainter oldDelegate) => true;
}

/// A finite three-tap demonstration; never sends taps or consumes a heart.
class TutorialHand extends StatefulWidget {
  const TutorialHand({super.key, required this.target});
  final Offset target;
  @override
  State<TutorialHand> createState() => _TutorialHandState();
}

class _TutorialHandState extends State<TutorialHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      motion.value = 1;
    } else if (!started) {
      motion.forward();
    }
    started = true;
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: motion,
      builder: (_, _) =>
          CustomPaint(painter: _HandPainter(widget.target, motion.value)),
    ),
  );
}

class _HandPainter extends CustomPainter {
  _HandPainter(this.target, this.progress);
  final Offset target;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final cycle = progress >= 1 ? .5 : (progress * 3) % 1;
    final press = sin(cycle * pi).clamp(0.0, 1.0);
    final ring = Paint()
      ..color = const Color(0xFFE6AF43).withValues(alpha: (1 - cycle) * .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (progress < 1) canvas.drawCircle(target, 8 + cycle * 18, ring);
    canvas.save();
    canvas.translate(target.dx, target.dy);
    if (target.dy > size.height - 75) canvas.rotate(pi);
    if (target.dx > size.width - 50) canvas.scale(-1.0, 1.0);
    canvas.translate(6 * (1 - press), 12 * (1 - press));
    canvas.scale(.88 + .12 * (1 - press));
    final hand = Path()
      ..moveTo(-5, 27)
      ..lineTo(-5, 3)
      ..cubicTo(-5, -5, 6, -5, 6, 3)
      ..lineTo(6, 19)
      ..cubicTo(8, 14, 15, 15, 16, 21)
      ..cubicTo(20, 17, 26, 20, 26, 25)
      ..cubicTo(31, 23, 36, 27, 35, 33)
      ..lineTo(32, 46)
      ..quadraticBezierTo(30, 53, 24, 56)
      ..lineTo(8, 56)
      ..quadraticBezierTo(2, 52, -2, 46)
      ..lineTo(-14, 33)
      ..cubicTo(-18, 27, -11, 21, -5, 27)
      ..close();
    canvas.drawShadow(hand, const Color(0x66071B33), 4, false);
    canvas.drawPath(
      hand,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF3D9), Color(0xFFE9B57D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(-16, -4, 52, 62)),
    );
    canvas.drawPath(
      hand,
      Paint()
        ..color = const Color(0xFF805937)
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 52, 23, 11),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFF7FAFF),
    );
    canvas.drawLine(
      const Offset(8, 59),
      const Offset(27, 59),
      Paint()
        ..color = const Color(0xFF178DDD)
        ..strokeWidth = 3,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HandPainter oldDelegate) =>
      oldDelegate.target != target || oldDelegate.progress != progress;
}

/// A short, finite completion wave beneath the victory screen.
class GoldenWavePainter extends CustomPainter {
  GoldenWavePainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius =
        size.longestSide * .7 * Curves.easeOutCubic.transform(progress);
    final fade = sin(progress * pi);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * (1 - progress) + 1
        ..color = const Color(0xFFE8BB59).withValues(alpha: fade * .5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    for (var i = 0; i < 18; i++) {
      final angle = i * pi * 2 / 18;
      final point = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawCircle(
        point,
        2 * fade,
        Paint()..color = const Color(0xFFC89632).withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant GoldenWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
