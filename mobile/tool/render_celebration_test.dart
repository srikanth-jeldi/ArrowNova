import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/game_screen.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game/puzzle.dart';

// Preview only: no extra fonts or raster assets are included in the app.
void main() {
  testWidgets('render celebration and blocked arrow feedback', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'ArrowNovaSans',
    )..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
    final emojiFont = File('C:/Windows/Fonts/seguiemj.ttf');
    if (emojiFont.existsSync()) {
      await (FontLoader('Segoe UI Emoji')..addFont(
            Future.value(ByteData.sublistView(emojiFont.readAsBytesSync())),
          ))
          .load();
    }
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'ArrowNovaSans'),
        home: GameScreen(
          level: 1,
          progress: PlayerProgress(
            trainingCompleted: true,
            sound: false,
            haptics: false,
          ),
          onComplete: (_, _) {},
          onSettingsChanged: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    ArrowBoard board() => tester.widget<ArrowBoard>(find.byType(ArrowBoard));
    final solution = board().game.puzzle.solution();
    for (final id in solution.take(solution.length - 1)) {
      board().onTap(id);
      await tester.pumpAndSettle();
    }
    board().onTap(solution.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    for (var i = 0; i < 45; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../.build-tmp/effects-preview/board-win-${i.toString().padLeft(2, '0')}.png',
        ),
      );
    }
    final game = GameSession(
      Puzzle(1, 8, 8, [
        ArrowPath(0, [const Cell(0, 2), const Cell(1, 2)]),
        ArrowPath(1, [const Cell(4, 2), const Cell(4, 3)]),
      ]),
    );
    for (var i = 0; i < 11; i++) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFFEAF7FF),
            body: Center(
              child: SizedBox(
                width: 330,
                height: 330,
                child: ArrowBoard(
                  game: game,
                  onTap: (_) {},
                  activeId: 0,
                  blocked: true,
                  progress: i / 10,
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../.build-tmp/effects-preview/blocked-$i.png'),
      );
    }
    expect(tester.takeException(), isNull);
  });
}
