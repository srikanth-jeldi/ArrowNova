import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/chapters_screen.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game/puzzle.dart';
import 'package:arrownova/victory_screen.dart';

void main() {
  test(
    'generated Classic continuation is stable, solvable and saved past 6000',
    () {
      for (final level in [6001, 6002, 6100, 10000, 100000]) {
        final p = LevelCatalog.get(level);
        expect(p.level, level);
        expect(p.arrows.length, LevelCatalog.arrowCount(level));
        expect(p.solution().length, p.arrows.length);
      }
      final progress = PlayerProgress(
        completed: {for (var n = 1; n <= 6001; n++) n},
        bestStars: {6001: 3},
      );
      final restored = PlayerProgress.fromJson(progress.toJson());
      expect(restored.nextLevel, 6002);
      expect(restored.bestStars[6001], 3);
      expect(restored.coins, 6001 * 40);
      expect(restored.endlessCompleted, 0);
    },
  );

  testWidgets(
    'Classic 6000 completes into 6001 then 6002; relaunch resumes 6002',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var progress = PlayerProgress(
        completed: {for (var n = 1; n < 6000; n++) n},
        trainingCompleted: true,
        sound: false,
        music: false,
        haptics: false,
      );
      // Keep one arrow for the boundary test, as if resuming a nearly solved board.
      final nearWin = GameSession(LevelCatalog.get(6000));
      final order = nearWin.puzzle.solution();
      for (final id in order.take(order.length - 1)) {
        nearWin.tap(id);
      }
      progress.runs['classic/6000'] = nearWin.snapshot(10000);
      Future<void> open() async {
        await tester.pumpWidget(ArrowNovaApp(initialProgress: progress));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue journey'));
        await tester.pumpAndSettle();
      }

      ArrowBoard board() => tester.widget<ArrowBoard>(find.byType(ArrowBoard));
      await open();
      for (final level in [6000, 6001]) {
        expect(board().game.puzzle.level, level);
        final game = board().game;
        for (final id in game.puzzle.solution(game.removed)) {
          board().onTap(id);
          await tester.pumpAndSettle();
        }
        expect(find.byType(VictoryScreen), findsOneWidget);
        expect(find.text('Journey complete'), findsNothing);
        expect(progress.nextLevel, level + 1);
        expect(progress.runs.containsKey('classic/$level'), isFalse);
        await tester.ensureVisible(find.text('Next level'));
        await tester.tap(find.text('Next level'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(board().game.puzzle.level, 6002);
      final cleared = board().game.puzzle.solution().first;
      board().onTap(cleared);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      progress = PlayerProgress.fromJson(progress.toJson());
      await open();
      expect(board().game.puzzle.level, 6002);
      expect(board().game.removed, {cleared});
      expect(progress.bestStars[6001], 3);
      await tester.pumpWidget(
        MaterialApp(
          home: ChaptersScreen(
            progress: progress,
            save: () {},
            openLevel: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue Level 6002'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
