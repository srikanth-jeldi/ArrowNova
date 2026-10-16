import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';

void main() {
  testWidgets('render real arrow exit frames', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ArrowNovaApp(
        initialProgress: PlayerProgress(
          completed: {1, 2, 3, 4},
          trainingCompleted: true,
          sound: false,
          music: false,
          haptics: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue journey'));
    await tester.pumpAndSettle();
    final board = tester.widget<ArrowBoard>(find.byType(ArrowBoard));
    final order = board.game.puzzle.solution();
    for (var i = 0; i < 90; i++) {
      if (i == 10) board.onTap(order[0]);
      if (i == 45) board.onTap(order[1]);
      await tester.pump(const Duration(milliseconds: 33));
      await expectLater(
        find.byType(ArrowNovaApp),
        matchesGoldenFile(
          '../.build-tmp/arrow-motion/frame-${i.toString().padLeft(3, '0')}.png',
        ),
      );
    }
    await tester.pumpAndSettle();
  });
}
