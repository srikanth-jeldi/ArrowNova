import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/core/review_service.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game_screen.dart';
import 'package:arrownova/victory_screen.dart';

void main() {
  test('three new wins and 30-day review cooldown survive storage', () {
    var p = PlayerProgress.fromJson({});
    final now = DateTime(2026, 10, 13);
    for (var i = 0; i < 2; i++) {
      p.review.recordWin();
      expect(p.review.claim(now), false);
    }
    p = PlayerProgress.fromJson(p.toJson());
    p.review.recordWin();
    expect(p.review.claim(now), true);
    p = PlayerProgress.fromJson(p.toJson());
    for (var i = 0; i < 8; i++) {
      p.review.recordWin();
    }
    expect(p.review.claim(now.add(const Duration(days: 29))), false);
    expect(p.review.claim(now.add(const Duration(days: 30))), true);
    expect(p.review.claim(now.add(const Duration(days: 60))), false);
    p.review.recordWin();
    p.review.resetStreak();
    expect(p.review.wins, 0);
    expect(
      PlayerProgress.fromJson({
        'review': {'wins': 'bad', 'lastRequested': false},
      }).review.wins,
      0,
    );
  });

  testWidgets('late availability cannot open review after leaving result', (
    tester,
  ) async {
    var current = true;
    var requests = 0;
    final available = Completer<bool>();
    final service = ReviewService(
      available: () => available.future,
      request: () async {
        requests++;
      },
    );
    final task = service.requestIfCurrent(() => current);
    current = false;
    available.complete(true);
    await task;
    expect(requests, 0);
  });

  testWidgets('third win requests one review, skips ad and never blocks Next', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final p = PlayerProgress(sound: false, haptics: false);
    p.review.wins = 2;
    p.levelsSinceAdBreak = 2;
    var reviews = 0, ads = 0;
    final nativeReview = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: 3,
          progress: p,
          onComplete: (level, stars) => p.completed.add(level),
          onSettingsChanged: () {},
          showBreakAd: () async {
            ads++;
          },
          reviewService: ReviewService(
            available: () async => true,
            request: () {
              reviews++;
              return nativeReview.future;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final game = tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game;
    for (final id in game.puzzle.solution()) {
      tester.widget<ArrowBoard>(find.byType(ArrowBoard)).onTap(id);
      await tester.pumpAndSettle();
    }
    expect(find.byType(VictoryScreen), findsOneWidget);
    expect(reviews, 1);
    expect(ads, 0);
    expect(p.review.lastRequested, isNotNull);
    expect(p.levelsSinceAdBreak, 0);
    await tester.ensureVisible(find.text('Next level'));
    await tester.tap(find.text('Next level'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game.puzzle.level,
      4,
    );
    nativeReview.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('unavailable inventory shows results without Opening ad', (
    tester,
  ) async {
    final p = PlayerProgress(sound: false, haptics: false);
    p.levelsSinceAdBreak = 2;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: 1,
          progress: p,
          onComplete: (level, stars) => p.completed.add(level),
          onSettingsChanged: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final game = tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game;
    for (final id in game.puzzle.solution()) {
      tester.widget<ArrowBoard>(find.byType(ArrowBoard)).onTap(id);
      await tester.pumpAndSettle();
      expect(find.text('Opening ad...'), findsNothing);
    }
    expect(find.byType(VictoryScreen), findsOneWidget);
    expect(find.text('Next level'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
