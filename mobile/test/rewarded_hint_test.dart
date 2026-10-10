import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/ads.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game_screen.dart';

void main() {
  for (final result in HintAdResult.values) {
    testWidgets('hint reward: $result', (tester) async {
      var calls = 0;
      final completion = Completer<HintAdResult>();
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            level: 1,
            progress: PlayerProgress(sound: false, haptics: false),
            onComplete: (_, _) {},
            onSettingsChanged: () {},
            showHintAd: () {
              calls++;
              return completion.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      ArrowBoard board() => tester.widget<ArrowBoard>(find.byType(ArrowBoard));
      await tester.tap(find.byTooltip('Hint'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(board().game.hinted, isNull);
      await tester.tap(find.byTooltip('Hint'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Watch ad for a hint'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(board().game.hinted, isNull);
      board().onTap(board().game.puzzle.solution().first);
      expect(board().game.removed, isEmpty);
      completion.complete(result);
      await tester.pumpAndSettle();
      expect(board().game.lives, 3);
      if (result == HintAdResult.earned) {
        expect(board().game.hinted, isNotNull);
        await tester.tap(find.byTooltip('Hint'));
        await tester.pumpAndSettle();
        expect(calls, 1); // Already highlighted: do not charge another ad.
      } else {
        expect(board().game.hinted, isNull);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
