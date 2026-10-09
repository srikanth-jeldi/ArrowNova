import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/victory_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final font in {
      'ArrowNovaSerif': 'assets/fonts/CormorantGaramond.ttf',
      'ArrowNovaSans': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  testWidgets(
    'three wrong taps, restart, win and saved unlock work end to end',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final progress = PlayerProgress(
        completed: {1, 2, 3},
        sound: false,
        haptics: false,
      );
      await tester.pumpWidget(ArrowNovaApp(initialProgress: progress));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/branding/logo.png'),
          tester.element(find.byType(HomeScreen)),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ArrowNovaApp),
        matchesGoldenFile('goldens/home.png'),
      );
      await tester.tap(find.text('Continue journey'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ArrowNovaApp),
        matchesGoldenFile('goldens/gameplay.png'),
      );
      ArrowBoard board() => tester.widget<ArrowBoard>(find.byType(ArrowBoard));
      final bad = board().game.puzzle.arrows
          .firstWhere((a) => !board().game.puzzle.canExit(a.id, {}))
          .id;
      // Two taps before animation finishes must only cost one heart.
      board().onTap(bad);
      board().onTap(bad);
      await tester.pumpAndSettle();
      expect(board().game.lives, 2);
      for (var i = 0; i < 2; i++) {
        board().onTap(bad);
        await tester.pumpAndSettle();
      }
      expect(find.text('No hearts left'), findsOneWidget);
      await tester.tap(find.text('Restart level'));
      await tester.pumpAndSettle();
      expect(board().game.lives, 3);
      expect(board().game.removed, isEmpty);
      board().onTap(bad);
      await tester.pumpAndSettle();
      final solution = board().game.puzzle.solution();
      for (final id in solution) {
        board().onTap(id);
        await tester.pumpAndSettle();
      }
      expect(find.text('Beautifully solved!'), findsOneWidget);
      expect(tester.widget<VictoryScreen>(find.byType(VictoryScreen)).stars, 2);
      expect(progress.completed, {1, 2, 3, 4});
      expect(progress.coins, 160);
      await tester.tap(find.text('Replay'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        board().onTap(bad);
        await tester.pumpAndSettle();
      }
      for (final id in solution) {
        board().onTap(id);
        await tester.pumpAndSettle();
      }
      expect(tester.widget<VictoryScreen>(find.byType(VictoryScreen)).stars, 1);
      expect(progress.bestStars[4], 2);
      expect(progress.coins, 160);
      await tester.tap(find.text('Next level'));
      await tester.pumpAndSettle();
      expect(board().game.puzzle.level, 5);
      expect(board().game.lives, 3);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'guest can start, see tutorial, play, hint, pause and resume on small phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ArrowNovaApp(
          initialProgress: PlayerProgress(sound: false, haptics: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play now'));
      await tester.pumpAndSettle();
      expect(find.text('Follow the arrow'), findsOneWidget);
      await tester.tap(find.text("Let's play"));
      await tester.pumpAndSettle();
      expect(find.byType(ArrowBoard), findsOneWidget);
      await tester.tap(find.byTooltip('Hint'));
      await tester.pumpAndSettle();
      expect(find.text('Follow the golden arrow'), findsOneWidget);
      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();
      expect(find.text('A quiet moment'), findsOneWidget);
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('three interactive lessons, victory, replay rewards and Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final progress = PlayerProgress(sound: false, haptics: false);
    await tester.pumpWidget(ArrowNovaApp(initialProgress: progress));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/art/victory-garden.png'),
        tester.element(find.byType(HomeScreen)),
      ),
    );
    await tester.tap(find.text('Play now'));
    await tester.pumpAndSettle();
    ArrowBoard board() => tester.widget<ArrowBoard>(find.byType(ArrowBoard));
    for (var level = 1; level <= 3; level++) {
      expect(
        find.text(
          [
            'Follow the arrow',
            'Protect your hearts',
            'Find the right order',
          ][level - 1],
        ),
        findsOneWidget,
      );
      await tester.tap(find.text("Let's play"));
      await tester.pumpAndSettle();
      if (level == 1) {
        await expectLater(
          find.byType(ArrowNovaApp),
          matchesGoldenFile('goldens/tutorial.png'),
        );
      }
      if (level == 2) {
        board().onTap(null);
        expect(board().game.lives, 3);
        board().onTap(0);
        board().onTap(0);
        await tester.pumpAndSettle();
        expect(board().game.lives, 2);
        expect(board().game.hinted, 1);
        board().onTap(0); // Coaching prevents repeatedly losing hearts here.
        await tester.pumpAndSettle();
        expect(board().game.lives, 2);
      }
      for (final id in board().game.puzzle.solution(board().game.removed)) {
        board().onTap(id);
        await tester.pumpAndSettle();
      }
      expect(find.byType(VictoryScreen), findsOneWidget);
      expect(tester.widget<VictoryScreen>(find.byType(VictoryScreen)).stars, 3);
      expect(progress.coins, level * 40);
      if (level == 1) {
        await expectLater(
          find.byType(ArrowNovaApp),
          matchesGoldenFile('goldens/victory.png'),
        );
        await tester.tap(find.text('Replay'));
        await tester.pumpAndSettle();
        for (final id in board().game.puzzle.solution()) {
          board().onTap(id);
          await tester.pumpAndSettle();
        }
        expect(progress.coins, 40);
        expect(find.text('Rewards already collected'), findsOneWidget);
      }
      await tester.tap(find.text('Next level'));
      await tester.pumpAndSettle();
    }
    expect(board().game.puzzle.level, 4);
    expect(find.text("Let's play"), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
