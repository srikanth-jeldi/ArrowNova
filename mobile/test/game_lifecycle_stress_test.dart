import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game_screen.dart';

void main() {
  testWidgets(
    'background during arrow exit preserves checkpoint and resumes to next level',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final progress = PlayerProgress(sound: false, haptics: false);
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: 1,
            progress: progress,
            onSettingsChanged: () {},
            onComplete: (level, stars) => progress.completed.add(level),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final game = tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game;
      final solution = game.puzzle.solution();
      tester.widget<ArrowBoard>(find.byType(ArrowBoard)).onTap(solution.first);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 4));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(game.removed, contains(solution.first));
      expect(progress.runs['classic/1']!['removed'], contains(solution.first));
      for (var i = 0; i < 30; i++) {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      for (final id in solution.skip(1)) {
        tester.widget<ArrowBoard>(find.byType(ArrowBoard)).onTap(id);
        await tester.pumpAndSettle();
      }
      expect(progress.completed, contains(1));
      expect(progress.runs.containsKey('classic/1'), false);
      await tester.tap(find.text('Next level'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game.puzzle.level,
        2,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
