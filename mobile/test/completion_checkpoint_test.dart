import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game_screen.dart';

void main() {
  testWidgets('last arrow commits completion before animation or app exit', (
    tester,
  ) async {
    final progress = PlayerProgress(sound: false, haptics: false);
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: 4,
          progress: progress,
          onSettingsChanged: () {},
          onComplete: (level, stars) {
            completions++;
            progress.completed.add(level);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final game = tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game;
    final solution = game.puzzle.solution();
    for (final id in solution.take(solution.length - 1)) {
      tester.widget<ArrowBoard>(find.byType(ArrowBoard)).onTap(id);
      await tester.pumpAndSettle();
    }
    expect(progress.runs.containsKey('classic/4'), isTrue);
    tester.widget<ArrowBoard>(find.byType(ArrowBoard)).onTap(solution.last);
    expect(completions, 1);
    expect(progress.runs.containsKey('classic/4'), isFalse);
    // Dispose while the last-arrow animation is still in flight.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    final restored = PlayerProgress.fromJson(progress.toJson());
    expect(restored.completed, contains(4));
    expect(restored.runs.containsKey('classic/4'), isFalse);
    expect(completions, 1);
  });
}
