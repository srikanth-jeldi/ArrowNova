import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/game/puzzle.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:flutter/material.dart';

void main() {
  Puzzle fixture() => Puzzle(1, 5, 5, [
    ArrowPath(0, [const Cell(0, 2), const Cell(1, 2)]),
    ArrowPath(1, [const Cell(3, 3), const Cell(3, 2), const Cell(3, 1)]),
  ]);
  test('blocked tap loses exactly one life; third locks game; restart restores same puzzle', () {
    final game = GameSession(fixture());
    expect(game.tap(null), TapResult.ignored);
    expect(game.lives, 3);
    for (var lives = 2; lives >= 0; lives--) {
      expect(game.tap(0), TapResult.blocked);
      expect(game.lives, lives);
      expect(game.removed, isEmpty);
    }
    expect(game.lost, isTrue);
    expect(game.tap(1), TapResult.ignored);
    game.restart();
    expect(game.lives, 3);
    expect(game.mistakes, 0);
    expect(game.tap(1), TapResult.cleared);
    expect(game.tap(1), TapResult.ignored);
    expect(game.tap(0), TapResult.cleared);
    expect(game.won, isTrue);
  });
  test('hint points to safe exit and does not mutate progress or lives', () {
    final game = GameSession(fixture());
    expect(game.hint(), 1);
    expect(game.lives, 3);
    expect(game.removed, isEmpty);
  });
  test('all 500 levels have unique non-overlapping connected paths and a complete solution', () {
    final fingerprints = <String>{};
    for (var level = 1; level <= LevelCatalog.count; level++) {
      final puzzle = LevelCatalog.get(level);
      expect(
        puzzle.arrows.length,
        greaterThanOrEqualTo(level <= 3 ? 3 : 5),
        reason: 'Level $level',
      );
      final occupied = <Cell>{};
      for (final arrow in puzzle.arrows) {
        for (var i = 0; i < arrow.cells.length; i++) {
          final c = arrow.cells[i];
          expect(puzzle.contains(c), isTrue);
          expect(occupied.add(c), isTrue, reason: 'overlap level $level');
          if (i > 0) {
            final d = c - arrow.cells[i - 1];
            expect(d.x.abs() + d.y.abs(), 1);
          }
        }
      }
      final solution = puzzle.solution();
      expect(
        solution.length,
        puzzle.arrows.length,
        reason: 'Unsolvable level $level',
      );
      final session = GameSession(puzzle);
      for (final id in solution) {
        expect(session.tap(id), TapResult.cleared);
      }
      expect(session.won, isTrue);
      expect(session.lives, 3);
      fingerprints.add(
        puzzle.arrows
            .map((a) => a.cells.map((c) => '${c.x},${c.y}').join(':'))
            .join('|'),
      );
    }
    expect(fingerprints.length, LevelCatalog.count);
  });
  test('hit testing ignores empty space and removed arrows', () {
    final puzzle = fixture();
    final g = BoardGeometry(puzzle, const Size(300, 400));
    expect(g.hit(g.point(const Cell(1, 2)), {}), 0);
    expect(g.hit(g.point(const Cell(1, 2)), {0}), isNull);
    expect(g.hit(Offset.zero, {}), isNull);
  });
  test('progress roundtrip preserves unlocks and does not duplicate replay rewards', () {
    final p = PlayerProgress(completed: {1, 2}, sound: false);
    p.completed.add(2);
    final restored = PlayerProgress.fromJson(p.toJson());
    expect(restored.coins, 80);
    expect(restored.gardenPoints, 20);
    expect(restored.nextLevel, 3);
    expect(restored.unlocked(3), isTrue);
    expect(restored.unlocked(4), isFalse);
    expect(restored.sound, isFalse);
  });
}
