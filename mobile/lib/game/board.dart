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
  });
  final GameSession game;
  final ValueChanged<int?> onTap;
  final int? activeId;
  final bool blocked;
  final double progress;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      final geometry = BoardGeometry(game.puzzle, size);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (event) =>
            onTap(geometry.hit(event.localPosition, game.removed)),
        child: CustomPaint(
          size: size,
          painter: ArrowPainter(
            game: game,
            geometry: geometry,
            activeId: activeId,
            blocked: blocked,
            progress: progress,
            onTap: onTap,
          ),
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
    var nearest = step * .32;
    int? selected;
    for (final arrow in puzzle.arrows) {
      if (removed.contains(arrow.id)) continue;
      for (var i = 1; i < arrow.cells.length; i++) {
        final a = point(arrow.cells[i - 1]);
        final b = point(arrow.cells[i]);
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
  });
  final GameSession game;
  final BoardGeometry geometry;
  final int? activeId;
  final bool blocked;
  final double progress;
  final ValueChanged<int?> onTap;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    // Quiet dot grid makes spacing readable without competing with the paths.
    final dot = Paint()..color = const Color(0x14265578);
    for (var y = 0; y < game.puzzle.height; y++) {
      for (var x = 0; x < game.puzzle.width; x++) {
        canvas.drawCircle(geometry.point(Cell(x, y)), .8, dot);
      }
    }
    for (final arrow in game.puzzle.arrows) {
      if (game.removed.contains(arrow.id) && arrow.id != activeId) continue;
      canvas.save();
      final isError = arrow.id == activeId && blocked;
      if (isError) {
        canvas.translate(sin(progress * pi * 6) * 3 * (1 - progress), 0);
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
            Curves.easeInCubic.transform(progress) *
            (originalLength + max(size.width, size.height) * 1.3);
        head += dir * travel;
        path.lineTo(head.dx, head.dy);
        visible = path.computeMetrics().first.extractPath(
          travel,
          originalLength + travel,
        );
      }
      final hint = game.hinted == arrow.id;
      final width = geometry.step * .17;
      final dark = isError
          ? const Color(0xFF972437)
          : hint
          ? const Color(0xFF916114)
          : const Color(0xFF074278);
      final light = isError
          ? const Color(0xFFFF8588)
          : hint
          ? const Color(0xFFFFE3A0)
          : const Color(0xFF5BDDFF);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.save();
      canvas.translate(1.2, 3);
      canvas.drawPath(
        visible,
        stroke
          ..color = const Color(0x30042544)
          ..strokeWidth = width + 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.restore();
      stroke.maskFilter = null;
      canvas.drawPath(
        visible,
        stroke
          ..color = dark
          ..strokeWidth = width + 1.7,
      );
      canvas.drawPath(
        visible,
        stroke
          ..shader = LinearGradient(
            colors: [
              light,
              hint ? const Color(0xFFE0AE42) : const Color(0xFF087DE0),
              dark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Offset.zero & size)
          ..strokeWidth = width,
      );
      stroke.shader = null;
      canvas.save();
      canvas.translate(-.65, -.9);
      canvas.drawPath(
        visible,
        stroke
          ..color = light.withValues(alpha: .78)
          ..strokeWidth = max(1.0, width * .23),
      );
      canvas.restore();
      final normal = Offset(-dir.dy, dir.dx);
      final tip = head + dir * geometry.step * .13;
      final base = head - dir * geometry.step * .22;
      final triangle = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          (base + normal * geometry.step * .19).dx,
          (base + normal * geometry.step * .19).dy,
        )
        ..lineTo(
          (base - normal * geometry.step * .19).dx,
          (base - normal * geometry.step * .19).dy,
        )
        ..close();
      canvas.drawShadow(triangle, const Color(0x80062C51), 2, false);
      canvas.drawPath(
        triangle,
        Paint()
          ..shader = LinearGradient(colors: [light, dark])
              .createShader(triangle.getBounds()),
      );
      canvas.drawPath(
        triangle,
        Paint()
          ..color = light
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
      canvas.restore();
    }
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
