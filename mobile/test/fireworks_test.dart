import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/victory_screen.dart';

void main() {
  for (final stars in [1, 2, 3]) {
    testWidgets('fireworks finish and controls work with $stars stars', (
      tester,
    ) async {
      var next = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: VictoryScreen(
            stars: stars,
            level: 1,
            moves: 30,
            elapsed: const Duration(seconds: 20),
            firstCompletion: true,
            totalCoins: 40,
            onNext: () => next++,
            onReplay: () {},
            onHome: () {},
          ),
        ),
      );
      expect(find.byType(VictoryFireworks), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.binding.hasScheduledFrame, true);
      await tester.tap(find.text('Next level'));
      expect(next, 1);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, false);
      expect(find.byKey(ValueKey('earned-star-${stars - 1}')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('reduced motion does not schedule fireworks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SizedBox(width: 390, height: 700, child: VictoryFireworks()),
        ),
      ),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, false);
    expect(tester.takeException(), isNull);
  });
}
