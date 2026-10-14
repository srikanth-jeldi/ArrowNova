import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/puzzle.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game_screen.dart';
import 'package:arrownova/victory_screen.dart';
import 'package:arrownova/app.dart';

void main() {
  testWidgets('Home opens the next Endless round beyond the Classic cap', (
    tester,
  ) async {
    final progress = PlayerProgress(
      endlessCompleted: 6000,
      sound: false,
      music: false,
      haptics: false,
    );
    await tester.pumpWidget(ArrowNovaApp(initialProgress: progress));
    await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Endless puzzles'), 300);
    await tester.tap(find.text('Endless puzzles'));
    await tester.pumpAndSettle();
    final board = tester.widget<ArrowBoard>(find.byType(ArrowBoard));
    expect(board.game.puzzle.level, 6001);
    expect(find.text('ROUND 6001 · ENDLESS'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  test('endless boards remain solvable, bounded and stable beyond 6000', () {
    final layouts = <String>{};
    for (final n in [...List.generate(200, (i) => i + 1), 6000, 6001, 100000]) {
      final p = EndlessCatalog.get(n);
      expect(p.arrows.length, inInclusiveRange(10, 80));
      final cells = <Cell>{};
      for (final a in p.arrows) {
        for (var i = 0; i < a.cells.length; i++) {
          expect(p.contains(a.cells[i]) && cells.add(a.cells[i]), isTrue);
          if (i > 0) {
            final d = a.cells[i] - a.cells[i - 1];
            expect(d.x.abs() + d.y.abs(), 1);
          }
        }
      }
      final game = GameSession(p);
      expect(layouts.add(game.layoutKey), isTrue);
      for (final id in p.solution()) {
        expect(game.tap(id), TapResult.cleared);
      }
      expect(game.won && game.lives == 3, isTrue);
    }
    final first = GameSession(EndlessCatalog.get(1));
    expect(first.layoutKey, layouts.first);
  });

  test(
    'endless progress roundtrips without duplicate rewards or Classic unlocks',
    () {
      final p = PlayerProgress.fromJson({});
      expect(p.nextEndlessRound, 1);
      expect(p.completeEndless(2), isFalse);
      expect(p.completeEndless(1), isTrue);
      expect(p.completeEndless(1), isFalse);
      final restored = PlayerProgress.fromJson(p.toJson());
      expect(restored.nextEndlessRound, 2);
      expect(restored.coins, 40);
      expect(restored.gardenPoints, 10);
      expect(restored.completed, isEmpty);
    },
  );

  testWidgets(
    'unfinished round resumes; completed round advances without stale save',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var progress = PlayerProgress(sound: false, music: false, haptics: false);
      Future<void> open() async {
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              level: progress.nextEndlessRound,
              endless: true,
              progress: progress,
              onComplete: (round, stars) => progress.completeEndless(round),
              onSettingsChanged: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      ArrowBoard board() => tester.widget<ArrowBoard>(find.byType(ArrowBoard));
      await open();
      final first = board().game.puzzle.solution().first;
      board().onTap(first);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      progress = PlayerProgress.fromJson(progress.toJson());
      await open();
      expect(board().game.removed, {first});
      final rest = board().game.puzzle.solution(board().game.removed);
      for (final id in rest) {
        board().onTap(id);
        await tester.pumpAndSettle();
      }
      expect(find.byType(VictoryScreen), findsOneWidget);
      expect(progress.nextEndlessRound, 2);
      expect(progress.runs.containsKey('endless/1'), isFalse);
      await tester.ensureVisible(find.text('Next round'));
      await tester.tap(find.text('Next round'));
      await tester.pumpAndSettle();
      expect(board().game.puzzle.level, 2);
      expect(board().game.removed, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      progress = PlayerProgress.fromJson(progress.toJson());
      await open();
      expect(board().game.puzzle.level, 2);
      expect(progress.coins, 40);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
