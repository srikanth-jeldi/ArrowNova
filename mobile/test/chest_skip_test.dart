import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/ads.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/daily_chest_screen.dart';
import 'package:arrownova/game/daily.dart';
import 'package:arrownova/game/puzzle.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game_screen.dart';

void main() {
  test('skip survives reload, unlocks next level but earns no rewards', () {
    final p = PlayerProgress();
    p.skip(1);
    final loaded = PlayerProgress.fromJson(p.toJson());
    expect(loaded.nextLevel, 2);
    expect(loaded.unlocked(2), true);
    expect(loaded.completed, isEmpty);
    expect(loaded.bestStars, isEmpty);
    expect(loaded.coins, 0);
    expect(loaded.gardenPoints, 0);
    expect(loaded.levelsSinceAdBreak, 0);
  });
  test('chest rewards once, resets daily and has five distinct solvable hard boards', () {
    final day = DateTime(2026, 10, 10);
    final p = PlayerProgress();
    expect(p.completeChest(day, 0, 3), false);
    p.unlockChest(day);
    expect(p.completeChest(day, 0, 2), true);
    expect(p.completeChest(day, 0, 3), false);
    expect(p.coins, 40);
    expect(p.gardenPoints, 10);
    final loaded = PlayerProgress.fromJson(p.toJson());
    expect(loaded.chestUnlocked(day), true);
    expect(loaded.chestUnlocked(day.add(const Duration(days: 1))), false);
    final levels = <int>{};
    for (var i = 0; i < 5; i++) {
      final puzzle = DailyChestCatalog.get(day, i);
      levels.add(puzzle.level);
      expect(LevelCatalog.isHard(puzzle.level), true);
      expect(puzzle.solution().length, puzzle.arrows.length);
    }
    expect(levels.length, 5);
    expect(loaded.completed, isEmpty);
  });
  for (final result in HintAdResult.values) {
    testWidgets('skip only on earned reward: $result', (tester) async {
      final p = PlayerProgress(sound: false, haptics: false);
      final reward = Completer<HintAdResult>();
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: 51,
            progress: p,
            onComplete: (_, _) {},
            onSettingsChanged: () {},
            showHintAd: () => reward.future,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Skip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Watch ad to skip'));
      await tester.pumpAndSettle();
      expect(p.skipped, isEmpty);
      reward.complete(result);
      await tester.pumpAndSettle();
      final board = tester.widget<ArrowBoard>(find.byType(ArrowBoard));
      expect(board.game.puzzle.level, result == HintAdResult.earned ? 52 : 51);
      expect(p.skipped.contains(51), result == HintAdResult.earned);
      expect(p.coins, 0);
      expect(tester.takeException(), isNull);
    });
    testWidgets('chest only unlocks on earned reward: $result', (tester) async {
      final p = PlayerProgress();
      final day = DateTime(2026, 10, 10);
      var calls = 0;
      final reward = Completer<HintAdResult>();
      await tester.pumpWidget(
        MaterialApp(
          home: DailyChestScreen(
            progress: p,
            onChanged: () {},
            now: () => day,
            showAd: () {
              calls++;
              return reward.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Watch ad · unlock 5 puzzles'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(p.chestUnlocked(day), false);
      reward.complete(result);
      await tester.pumpAndSettle();
      expect(p.chestUnlocked(day), result == HintAdResult.earned);
      expect(p.coins, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
