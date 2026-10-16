import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game/puzzle.dart';

void main() {
  test('blocked movement reaches contact and retraces without overshoot', () {
    final path = Path()
      ..moveTo(20, 20)
      ..lineTo(20, 60)
      ..lineTo(60, 60);
    const head = Offset(60, 60);
    const direction = Offset(1, 0);
    var previous = 0.0;
    for (var i = 0; i <= 100; i++) {
      final fraction = ArrowBlockedMotion.fraction(i / 100);
      expect(fraction, inInclusiveRange(0, 1));
      if (i <= 42) expect(fraction, greaterThanOrEqualTo(previous));
      if (i >= 50) expect(fraction, lessThanOrEqualTo(previous));
      final frame = ArrowExitFrame.atDistance(
        path,
        head,
        direction,
        80 * fraction,
      );
      expect(frame.body.computeMetrics().first.length, closeTo(80, .01));
      expect(frame.head.dx, lessThanOrEqualTo(140));
      if (i == 100) {
        expect(frame.head, head);
        expect(frame.body.getBounds(), path.getBounds());
      }
      previous = fraction;
    }
    expect(ArrowBlockedMotion.fraction(.42), 1);
    expect(ArrowBlockedMotion.fraction(.49), 1);
  });

  test('contact selects nearest remaining blocker', () {
    final arrow = ArrowPath(0, [const Cell(0, 2), const Cell(1, 2)]);
    final puzzle = Puzzle(1, 8, 8, [
      arrow,
      ArrowPath(1, [const Cell(3, 2), const Cell(3, 3)]),
      ArrowPath(2, [const Cell(6, 2), const Cell(6, 3)]),
    ]);
    final game = GameSession(puzzle);
    final painter = ArrowPainter(
      game: game,
      geometry: BoardGeometry(puzzle, const Size(300, 300)),
      onTap: (_) {},
    );
    expect(painter.blockerContact(arrow), const Cell(3, 2));
    game.removed.add(1);
    expect(painter.blockerContact(arrow), const Cell(6, 2));
    game.removed.add(2);
    expect(painter.blockerContact(arrow), isNull);
  });
}
