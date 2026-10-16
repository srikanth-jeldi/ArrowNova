import 'dart:async';

import 'package:flutter/services.dart';
import 'package:arrownova/app.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/ads.dart';
import 'package:arrownova/core/chapter_gate.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/chapters.dart';
import 'package:arrownova/chapters_screen.dart';
import 'package:arrownova/game_screen.dart';
import 'package:arrownova/game/board.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final font in {
      'ArrowNovaSans': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  test('chapter boundaries, migration and durable unlocks', () {
    expect(ChapterCatalog.count, 60);
    expect(ChapterCatalog.of(100), 1);
    expect(ChapterCatalog.of(101), 2);
    expect(ChapterCatalog.last(60), 6000);
    final p = PlayerProgress();
    expect(p.unlockChapter(2), false);
    p.completed.add(100);
    expect(p.chapterEligible(2), true);
    expect(p.chapterOpen(2), false);
    expect(p.unlockChapter(2), true);
    final saved = PlayerProgress.fromJson(p.toJson());
    expect(saved.chapterOpen(2), true);
    expect(saved.chapterOpen(3), false);
    final old = PlayerProgress.fromJson({
      'completed': [799, 800],
      'stars': {'800': 3},
    });
    expect(old.chapterOpen(9), true);
    expect(old.chapterOpen(10), false);
    expect(old.bestStars[800], 3);
    expect(p.unlockChapter(61), false);
  });
  testWidgets('boundary skip uses one reward for skip and chapter', (
    tester,
  ) async {
    final p = PlayerProgress(chapters: {1}, sound: false, haptics: false);
    var ads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: 100,
          progress: p,
          onComplete: (_, _) {},
          onSettingsChanged: () {},
          showHintAd: () async {
            ads++;
            return HintAdResult.earned;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch ad to skip'));
    await tester.pumpAndSettle();
    expect(ads, 1);
    expect(p.chapterOpen(2), true);
    expect(p.skipped, {100});
    expect(
      tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game.puzzle.level,
      101,
    );
    expect(p.consumeAdBreak(), false);
    expect(p.coins, 0);
    expect(tester.takeException(), isNull);
  });
  for (final outcome in HintAdResult.values) {
    testWidgets('chapter gate reward $outcome without double ads', (
      tester,
    ) async {
      final p = PlayerProgress(
        chapters: {1},
        completed: {100},
        levelsSinceAdBreak: 2,
      );
      final reward = Completer<HintAdResult>();
      var calls = 0, saves = 0;
      bool? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  opened = await ensureChapter(
                    context,
                    p,
                    101,
                    () => saves++,
                    showAd: () {
                      calls++;
                      return reward.future;
                    },
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Watch ad · unlock chapter'));
      await tester.pump();
      await tester.tap(find.text('Opening ad…'));
      await tester.pump();
      expect(calls, 1);
      expect(p.chapterOpen(2), false);
      reward.complete(outcome);
      await tester.pumpAndSettle();
      expect(p.chapterOpen(2), outcome == HintAdResult.earned);
      if (outcome == HintAdResult.earned) {
        expect(opened, true);
        expect(saves, 1);
        expect(p.consumeAdBreak(), false);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(calls, 1);
      } else {
        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();
        expect(opened, false);
        expect(saves, 0);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('world browser shows only selected chapter on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ArrowNovaApp(initialProgress: PlayerProgress()));
    final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: ChaptersScreen(
          progress: PlayerProgress(),
          save: () {},
          openLevel: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('60 chapters · 6,000 puzzles'), findsOneWidget);
    expect(find.text('Levels 1–100'), findsOneWidget);
    expect(find.text('101'), findsNothing);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/chapters.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
