import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/victory_screen.dart';

void main() {
  testWidgets('levels 5 through 7 complete and total coins persist on replay', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final progress = PlayerProgress(
      completed: {1, 2, 3, 4},
      trainingCompleted: true,
      sound: false,
      haptics: false,
      music: false,
    );
    await tester.pumpWidget(ArrowNovaApp(initialProgress: progress));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue journey'));
    await tester.pumpAndSettle();
    Future<void> solve() async {
      final game = tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game;
      for (final id in game.puzzle.solution()) {
        tester.widget<ArrowBoard>(find.byType(ArrowBoard)).onTap(id);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }

    for (final level in [5, 6, 7]) {
      await solve();
      expect(find.byType(VictoryScreen), findsOneWidget);
      expect(find.text('Total coins: ${level * 40}'), findsOneWidget);
      expect(find.text('+40'), findsOneWidget);
      expect(progress.coins, level * 40);
      if (level < 7) {
        await tester.ensureVisible(find.text('Next level'));
        await tester.tap(find.text('Next level'));
        await tester.pumpAndSettle();
      }
    }
    await tester.ensureVisible(find.text('Replay'));
    await tester.tap(find.text('Replay'));
    await tester.pumpAndSettle();
    await solve();
    expect(find.text('+0'), findsOneWidget);
    expect(find.text('Total coins: 280'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
