import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/victory_screen.dart';
import 'package:arrownova/clapping_hands.dart';

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
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('👏'), findsNothing);
      expect(
        find.byType(ClappingHands),
        stars == 3 ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(switch (stars) {
          3 => 'Perfect!',
          2 => 'Well done!',
          _ => 'Nice solve!',
        }),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('victory-praise')), findsNothing);
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
  testWidgets('reduced motion keeps the quiet victory subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(child: VictoryPraise(stars: 3)),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('victory-praise')), findsNothing);
    expect(tester.binding.hasScheduledFrame, false);
  });
}
