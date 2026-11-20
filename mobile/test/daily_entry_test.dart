import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/daily_challenge_screen.dart';
import 'package:arrownova/game/daily.dart';
import 'package:arrownova/game_screen.dart';
import 'package:arrownova/victory_screen.dart';

void main() {
  for (final completedToday in [true, false]) {
    testWidgets(
      'daily entrance respects local day completion: $completedToday',
      (tester) async {
        final now = DateTime.now();
        final progress = PlayerProgress(sound: false, haptics: false);
        progress.completeDaily(
          completedToday ? now : DateTime(now.year, now.month, now.day - 1),
          3,
        );
        final balance = progress.coins;
        await tester.pumpWidget(ArrowNovaApp(initialProgress: progress));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Daily challenge'), 250);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Daily challenge'));
        await tester.pumpAndSettle();
        expect(find.byType(DailyChallengeScreen), findsOneWidget);
        expect(find.byType(GameScreen), findsNothing);
        if (completedToday) {
          expect(find.text('Today’s puzzle complete'), findsOneWidget);
          expect(find.text('Play daily puzzle'), findsNothing);
          await tester.pageBack();
          await tester.pumpAndSettle();
          await tester.tap(find.text('Daily challenge'));
          await tester.pumpAndSettle();
          expect(find.byType(GameScreen), findsNothing);
          expect(progress.dailyStars.length, 1);
          expect(progress.dailyStars[dayKey(now)], 3);
        } else {
          await tester.tap(find.text('Play daily puzzle'));
          await tester.pumpAndSettle();
          expect(find.byType(GameScreen), findsOneWidget);
        }
        expect(progress.coins, balance);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('completed daily victory has no replay action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VictoryScreen(
          level: 1,
          stars: 3,
          moves: 30,
          elapsed: const Duration(seconds: 50),
          firstCompletion: true,
          totalCoins: 60,
          dailyLabel: 'Today',
          dailyStreak: 1,
          allowReplay: false,
          onNext: () {},
          onReplay: () {},
          onHome: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Replay'), findsNothing);
    expect(find.text('Daily Challenge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
