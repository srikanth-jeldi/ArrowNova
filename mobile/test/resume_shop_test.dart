import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game_screen.dart';
import 'package:arrownova/theme_shop_screen.dart';

void main() {
  testWidgets('leaving and reopening resumes the board with spent hearts', (
    tester,
  ) async {
    var progress = PlayerProgress(sound: false, haptics: false);
    Widget screen() => MaterialApp(
      home: GameScreen(
        level: 4,
        progress: progress,
        onComplete: (_, _) {},
        onSettingsChanged: () {},
      ),
    );
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    ArrowBoard board() => tester.widget<ArrowBoard>(find.byType(ArrowBoard));
    final game = board().game;
    board().onTap(game.puzzle.solution().first);
    await tester.pumpAndSettle();
    final blocked = game.puzzle.arrows.firstWhere(
      (a) =>
          !game.removed.contains(a.id) &&
          !game.puzzle.canExit(a.id, game.removed),
    );
    board().onTap(blocked.id);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    progress = PlayerProgress.fromJson(progress.toJson());
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(board().game.removed, game.removed);
    expect(board().game.lives, 2);
    expect(board().game.mistakes, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'theme purchase requires confirmation and owned selection is free',
    (tester) async {
      final progress = PlayerProgress(completed: {1, 2, 3, 4, 5, 6});
      await tester.pumpWidget(
        MaterialApp(
          home: ThemeShopScreen(progress: progress, onChanged: () {}),
        ),
      );
      await tester.pumpAndSettle();
      final unlock = find.text('Unlock · 200 coins');
      await tester.scrollUntilVisible(unlock, 200);
      await tester.pumpAndSettle();
      await tester.tap(unlock);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(progress.coins, 240);
      await tester.tap(unlock);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(progress.coins, 40);
      expect(progress.selectedTheme, 'amethyst');
      final use = find.text('Use theme');
      await tester.scrollUntilVisible(use, -200);
      await tester.pumpAndSettle();
      await tester.tap(use);
      await tester.pumpAndSettle();
      expect(progress.selectedTheme, 'crystal');
      expect(progress.coins, 40);
      expect(tester.takeException(), isNull);
    },
  );
}
