import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/ads.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game_screen.dart';

void main() {
  for (final result in HintAdResult.values) {
    testWidgets(
      'revive preserves puzzle and grants only earned hearts: $result',
      (tester) async {
        final reward = Completer<HintAdResult>();
        var calls = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: GameScreen(
              level: 1,
              progress: PlayerProgress(sound: false, haptics: false),
              onComplete: (_, _) {},
              onSettingsChanged: () {},
              showHintAd: () {
                calls++;
                return reward.future;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        ArrowBoard board() =>
            tester.widget<ArrowBoard>(find.byType(ArrowBoard));
        final game = board().game;
        board().onTap(game.puzzle.solution().first);
        await tester.pumpAndSettle();
        final cleared = Set<int>.of(game.removed);
        final blocked = game.puzzle.arrows
            .firstWhere(
              (a) =>
                  !game.removed.contains(a.id) &&
                  !game.puzzle.canExit(a.id, game.removed),
            )
            .id;
        for (var i = 0; i < 3; i++) {
          board().onTap(blocked);
          await tester.pumpAndSettle();
        }
        expect(game.lost, isTrue);
        await tester.tap(find.text('Watch ad · +3 hearts'));
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(game.lives, 0);
        reward.complete(result);
        await tester.pumpAndSettle();
        expect(game.removed, cleared);
        expect(game.mistakes, 3);
        expect(game.lives, result == HintAdResult.earned ? 3 : 0);
        if (result != HintAdResult.earned) {
          await tester.tap(find.text('No thanks, restart'));
          await tester.pumpAndSettle();
          expect(game.lives, 3);
          expect(game.removed, isEmpty);
        } else {
          expect(game.revive(), isFalse);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
