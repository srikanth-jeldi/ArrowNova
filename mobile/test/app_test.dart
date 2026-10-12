import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/victory_screen.dart';

void main() {
  testWidgets('coin shop fits a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ArrowNovaApp(
        initialProgress: PlayerProgress(
          completed: {1, 2, 3, 4, 5, 6},
          sound: false,
          haptics: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crystal rewards'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ArrowNovaApp),
      matchesGoldenFile('goldens/theme-shop.png'),
    );
    expect(tester.takeException(), isNull);
  });
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
      expect(find.text('Live Duel'), findsNothing);
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/branding/logo.webp'),
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
      await tester.tap(find.text('No thanks, restart'));
      await tester.pumpAndSettle();
      expect(board().game.lives, 3);
      expect(board().game.removed, isEmpty);
      board().onTap(bad);
      await tester.pumpAndSettle();
      final solution = board().game.puzzle.solution();
      for (final id in solution) {
        board().onTap(id);
        if (id == solution.last) {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 510));
          await tester.pump(const Duration(milliseconds: 150));
          expect(
            find.byKey(const ValueKey('board-golden-wave')),
            findsOneWidget,
          );
          expect(find.byType(VictoryScreen), findsNothing);
          // Completion feedback must keep input locked and reward only once.
          board().onTap(id);
        }
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
  testWidgets('two practice rounds precede Level 1 without rewards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final progress = PlayerProgress(sound: false, haptics: false);
    await tester.pumpWidget(ArrowNovaApp(initialProgress: progress));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play now'));
    await tester.pumpAndSettle();
    ArrowBoard board() => tester.widget<ArrowBoard>(find.byType(ArrowBoard));
    for (var round = 1; round <= 2; round++) {
      expect(find.text('PRACTICE $round / 2'), findsOneWidget);
      await tester.tap(find.text("Let's play"));
      await tester.pumpAndSettle();
      if (round == 1) {
        await expectLater(
          find.byType(ArrowNovaApp),
          matchesGoldenFile('goldens/tutorial.png'),
        );
        final other = board().game.puzzle.arrows
            .firstWhere((a) => a.id != board().game.hinted)
            .id;
        board().onTap(other);
        await tester.pumpAndSettle();
        expect(board().game.removed, isEmpty);
      } else {
        board().onTap(null);
        expect(board().game.lives, 3);
        board().onTap(0);
        await tester.pumpAndSettle();
        expect(board().game.lives, 2);
        board().onTap(0);
        await tester.pumpAndSettle();
        expect(board().game.lives, 2);
      }
      while (!board().game.won) {
        board().onTap(board().game.hinted);
        await tester.pumpAndSettle();
      }
      expect(find.text('Practice complete!'), findsOneWidget);
      expect(progress.completed, isEmpty);
      expect(progress.coins, 0);
      expect(progress.bestStars, isEmpty);
      await tester.tap(
        find.text(round == 1 ? 'Practice round 2' : 'Start Level 1'),
      );
      await tester.pumpAndSettle();
    }
    expect(progress.trainingCompleted, isTrue);
    expect(
      PlayerProgress.fromJson(progress.toJson()).trainingCompleted,
      isTrue,
    );
    expect(board().game.puzzle.level, 1);
    expect(board().game.puzzle.arrows.length, greaterThanOrEqualTo(20));
    expect(board().game.lives, 3);
    expect(find.text("Let's play"), findsNothing);
    for (final id in board().game.puzzle.solution()) {
      board().onTap(id);
      await tester.pumpAndSettle();
    }
    expect(find.byType(VictoryScreen), findsOneWidget);
    expect(tester.widget<VictoryScreen>(find.byType(VictoryScreen)).stars, 3);
    expect(progress.coins, 40);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue journey'));
    await tester.pumpAndSettle();
    expect(board().game.puzzle.level, 2);
    expect(find.text("Let's play"), findsNothing);
    expect(tester.takeException(), isNull);
    // Stopwatch uses wall time: freeze only the visual fixture, not gameplay.
    final theme = Theme.of(tester.element(find.byType(ArrowBoard)));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: VictoryScreen(
          level: 1,
          stars: 3,
          moves: 30,
          elapsed: const Duration(seconds: 4),
          firstCompletion: true,
          totalCoins: 40,
          onNext: () {},
          onReplay: () {},
          onHome: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/victory.png'),
    );
  });
  testWidgets(
    'dense expert board fits phone and supports precise zoomed taps',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final level in [1, 10, 100, 800]) {
        await tester.pumpWidget(
          ArrowNovaApp(
            key: ValueKey(level),
            initialProgress: PlayerProgress(
              completed: {for (var n = 1; n < level; n++) n},
              trainingCompleted: true,
              sound: false,
              haptics: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(level == 1 ? 'Play now' : 'Continue journey'),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ArrowNovaApp),
          matchesGoldenFile('goldens/dense-$level.png'),
        );
        expect(tester.takeException(), isNull);
      }
      final finder = find.byType(ArrowBoard);
      final board = tester.widget<ArrowBoard>(finder);
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final size = tester.getSize(finder);
      final geometry = BoardGeometry(board.game.puzzle, size);
      final arrow = board.game.puzzle.arrows.firstWhere(
        (a) => board.game.puzzle.canExit(a.id, {}),
      );
      final point = geometry.point(arrow.head);
      viewer.transformationController!.value = Matrix4.diagonal3Values(3, 3, 1)
        ..setTranslationRaw(
          size.width / 2 - point.dx * 3,
          size.height / 2 - point.dy * 3,
          0,
        );
      await tester.pumpAndSettle();
      final render = tester.renderObject<RenderBox>(finder);
      await tester.tapAt(render.localToGlobal(point));
      await tester.pumpAndSettle();
      expect(board.game.removed, {arrow.id});
      expect(board.game.lives, 3);
      expect(tester.takeException(), isNull);
    },
  );
}
