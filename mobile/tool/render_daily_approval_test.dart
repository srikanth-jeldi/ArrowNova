import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/daily_challenge_screen.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game/daily.dart';
import 'package:arrownova/game_screen.dart';
import 'package:arrownova/ui.dart';
import 'package:arrownova/victory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Daily Challenge flow and midnight rollover', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final font in {
      'ArrowNovaSans': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
    var date = DateTime(2026, 11, 20, 18, 30);
    final progress = PlayerProgress(sound: false, haptics: false);
    progress.completeDaily(DateTime(2026, 11, 19), 3);

    Future<void> capture(String file) async {
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../docs/previews/approval/daily-$file.png'),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: navy,
          fontFamily: 'ArrowNovaSans',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF35CEFF),
            brightness: Brightness.dark,
            surface: navy,
          ),
        ),
        home: Builder(
          builder: (context) => DailyChallengeScreen(
            progress: progress,
            now: () => date,
            enableReminders: () async => progress.dailyReminders = true,
            play: (selectedDate) => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => GameScreen(
                  level: 1,
                  progress: progress,
                  dailyDate: selectedDate,
                  onComplete: (_, stars) =>
                      progress.completeDaily(selectedDate, stars),
                  onSettingsChanged: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await capture('01-ready');
    await tester.tap(find.text('Play daily puzzle'));
    await capture('02-board');
    expect(find.byType(GameScreen), findsOneWidget);
    final firstBoard = tester.widget<ArrowBoard>(find.byType(ArrowBoard));
    final order = firstBoard.game.puzzle.solution();
    firstBoard.onTap(order.first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to Daily Challenge'));
    await tester.pumpAndSettle();
    final key = dayKey(date);
    expect(progress.runs['daily/$key']?['removed'], [order.first]);
    expect(find.text('Resume puzzle'), findsOneWidget);
    await capture('03-resume');
    await tester.tap(find.text('Resume puzzle'));
    await tester.pumpAndSettle();
    final resumedBoard = tester.widget<ArrowBoard>(find.byType(ArrowBoard));
    expect(resumedBoard.game.removed, {order.first});
    for (final id in order.skip(1)) {
      tester.widget<ArrowBoard>(find.byType(ArrowBoard)).onTap(id);
      await tester.pumpAndSettle();
    }
    final result = tester.widget<VictoryScreen>(find.byType(VictoryScreen));
    expect(progress.dailyStars[key], 3);
    expect(progress.streakRewards[key], 30);
    expect(progress.runs.containsKey('daily/$key'), isFalse);
    await tester.tap(find.widgetWithText(GoldButton, 'Daily Challenge'));
    await tester.pumpAndSettle();
    expect(find.text('Next puzzle in 5h 30m'), findsOneWidget);
    expect(find.text('Tomorrow’s streak bonus: +40 coins'), findsOneWidget);
    await capture('05-completed');
    await tester.tap(find.text('Remind me to play'));
    await tester.pumpAndSettle();
    expect(find.text('Puzzle reminders are on'), findsOneWidget);
    date = DateTime(2026, 11, 21);
    await tester.pump(const Duration(seconds: 15));
    expect(find.text('Play daily puzzle'), findsOneWidget);
    final hubContext = tester.element(find.byType(DailyChallengeScreen));
    final theme = Theme.of(hubContext);
    await tester.runAsync(
      () => precacheImage(
        ResizeImage.resizeIfNeeded(
          1080,
          null,
          const AssetImage('assets/art/victory-garden.webp'),
        ),
        hubContext,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('daily-result-preview'),
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: VictoryScreen(
          level: result.level,
          dailyLabel: result.dailyLabel,
          dailyStreak: result.dailyStreak,
          streakBonus: result.streakBonus,
          stars: result.stars,
          moves: result.moves,
          elapsed: const Duration(minutes: 2, seconds: 30),
          firstCompletion: result.firstCompletion,
          totalCoins: result.totalCoins,
          allowReplay: result.allowReplay,
          onNext: () {},
          onReplay: () {},
          onHome: () {},
        ),
      ),
    );
    await capture('04-result');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
