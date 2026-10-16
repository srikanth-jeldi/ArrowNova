import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/game/board_celebration.dart';

void main() {
  testWidgets(
    'board reaction is stable across frames and has no extra ticker',
    (tester) async {
      final seen = <String>{};
      for (var seed = 0; seed < 12; seed++) {
        Widget frame(double t) => MaterialApp(
          home: BoardWinCelebration(
            key: ValueKey(seed),
            stars: 3,
            seed: seed,
            progress: t,
          ),
        );
        await tester.pumpWidget(frame(.2));
        final label = tester
            .widget<Text>(find.byKey(const ValueKey('board-win-label')))
            .data!;
        seen.add(label);
        await tester.pumpWidget(frame(.8));
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('board-win-label')))
              .data,
          label,
        );
        await tester.pumpAndSettle();
        expect(tester.binding.hasScheduledFrame, false);
      }
      expect(seen.length, greaterThan(1));
      expect(tester.takeException(), isNull);
    },
  );
}
