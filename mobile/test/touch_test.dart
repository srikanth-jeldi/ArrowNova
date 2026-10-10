import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game/puzzle.dart';

void main() {
  test(
    'dense heads, near-path taps and nearest neighbours select correctly',
    () {
      final puzzle = Puzzle(1, 30, 30, [
        ArrowPath(0, [const Cell(2, 3), const Cell(3, 3)]),
        ArrowPath(1, [const Cell(2, 4), const Cell(3, 4)]),
      ]);
      final g = BoardGeometry(puzzle, const Size(310, 400));
      final head = g.point(const Cell(3, 3));
      expect(g.hit(head + Offset(g.step * .37, 0), {}), 0);
      expect(g.hit(g.point(const Cell(2, 3)) + const Offset(0, -7), {}), 0);
      expect(g.hit(g.point(const Cell(2, 4)) + const Offset(0, -2), {}), 1);
      expect(g.hit(head, {0, 1}), isNull);
      expect(g.hit(Offset.zero, {}), isNull);
    },
  );

  testWidgets('rapid safe taps are buffered without repeating a heart loss', (
    tester,
  ) async {
    final p = PlayerProgress(
      trainingCompleted: true,
      sound: false,
      music: false,
      haptics: false,
    );
    await tester.pumpWidget(ArrowNovaApp(initialProgress: p));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play now'));
    await tester.pumpAndSettle();
    ArrowBoard board() => tester.widget<ArrowBoard>(find.byType(ArrowBoard));
    final game = board().game;
    final order = game.puzzle.solution();
    board().onTap(order[0]);
    await tester.pump(const Duration(milliseconds: 30));
    board().onTap(order[1]);
    await tester.pumpAndSettle();
    expect(game.removed, containsAll(order.take(2)));
    expect(game.lives, 3);
    final wrong = game.puzzle.arrows.firstWhere(
      (a) =>
          !game.removed.contains(a.id) &&
          !game.puzzle.canExit(a.id, game.removed),
    );
    board().onTap(wrong.id);
    board().onTap(wrong.id);
    await tester.pumpAndSettle();
    expect(game.lives, 2);
    expect(tester.takeException(), isNull);
  });
}
