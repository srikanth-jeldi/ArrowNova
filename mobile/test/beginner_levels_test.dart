import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/game/puzzle.dart';

void main() {
  test('first 30 boards are small, connected, unique and solvable', () {
    final layouts = <String>{};
    for (var n = 1; n <= 30; n++) {
      final p = LevelCatalog.get(n);
      expect(p.arrows.length, LevelCatalog.arrowCount(n));
      expect(LevelCatalog.isHard(n), isFalse);
      final cells = <Cell>{};
      for (final a in p.arrows) {
        expect(
          a.cells.length,
          inInclusiveRange(
            2,
            n <= 10
                ? 6
                : n <= 20
                ? 10
                : 14,
          ),
        );
        for (var i = 0; i < a.cells.length; i++) {
          expect(p.contains(a.cells[i]) && cells.add(a.cells[i]), isTrue);
          if (i > 0) {
            final d = a.cells[i] - a.cells[i - 1];
            expect(d.x.abs() + d.y.abs(), 1);
          }
        }
      }
      expect(
        p.dependencyDepth,
        lessThanOrEqualTo(
          n <= 5
              ? 2
              : n <= 10
              ? 3
              : n <= 20
              ? 5
              : 7,
        ),
      );
      final game = GameSession(p);
      layouts.add(game.layoutKey);
      for (final id in p.solution()) {
        game.tap(id);
      }
      expect(game.won && game.lives == 3, isTrue);
    }
    expect(layouts.length, 30);
    expect(LevelCatalog.arrowCount(1), 5);
    expect(LevelCatalog.arrowCount(30), 30);
  });
  test('old early runs retain geometry and removals', () {
    for (final n in [1, 4, 10, 20, 30]) {
      final old = GameSession(LevelCatalog.get(n, legacy: true));
      old.tap(old.puzzle.solution().first);
      final data = old.snapshot(1234);
      final restored = GameSession(LevelCatalog.resume(n, data));
      expect(restored.restore(data), 1234);
      expect(restored.layoutKey, old.layoutKey);
      expect(restored.removed, old.removed);
    }
  });
}
