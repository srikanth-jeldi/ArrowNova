import 'package:arrownova/game/board_celebration.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/ad_session.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game_screen.dart';
import 'package:arrownova/victory_screen.dart';

void main() {
  testWidgets('lost ad callbacks keep result visible and recover Next level', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final progress = PlayerProgress(sound: false, haptics: false);
    progress.levelsSinceAdBreak = 2;
    var adCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: 5,
          progress: progress,
          onSettingsChanged: () {},
          onComplete: (level, stars) => progress.completed.add(level),
          showBreakAd: () {
            adCalls++;
            final done = Completer<void>();
            AdSession(done.complete);
            return done.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final game = tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game;
    final solution = game.puzzle.solution();
    for (final id in solution.take(solution.length - 1)) {
      tester.widget<ArrowBoard>(find.byType(ArrowBoard)).onTap(id);
      await tester.pumpAndSettle();
    }
    tester.widget<ArrowBoard>(find.byType(ArrowBoard)).onTap(solution.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(BoardWinCelebration), findsOneWidget);
    expect(find.byType(ArrowBoard), findsOneWidget);
    expect(find.byType(VictoryScreen), findsNothing);
    expect(progress.completed, contains(5));
    expect(adCalls, 0);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byType(BoardWinCelebration), findsOneWidget);
    expect(find.byType(VictoryScreen), findsNothing);
    expect(adCalls, 0);
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump();
    expect(find.byType(VictoryScreen), findsOneWidget);
    expect(find.byType(BoardWinCelebration), findsNothing);
    expect(progress.completed, contains(5));
    expect(progress.runs.containsKey('classic/5'), isFalse);
    expect(adCalls, 1);
    expect(find.text('Opening ad...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Next level'), findsOneWidget);
    await tester.ensureVisible(find.text('Next level'));
    await tester.tap(find.text('Next level'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game.puzzle.level,
      6,
    );
    expect(adCalls, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
