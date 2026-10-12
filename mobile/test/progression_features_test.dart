import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/puzzle.dart';

void main() {
  test('autosave preserves cleared arrows, spent hearts, hints and time', () {
    final game = GameSession(LevelCatalog.get(4));
    game.tap(game.puzzle.solution().first);
    final blocked = game.puzzle.arrows.firstWhere(
      (a) =>
          !game.removed.contains(a.id) &&
          !game.puzzle.canExit(a.id, game.removed),
    );
    game.tap(blocked.id);
    game.hint();
    final progress = PlayerProgress();
    progress.runs['classic/4'] = game.snapshot(42000);
    final loaded = PlayerProgress.fromJson(progress.toJson());
    final resumed = GameSession(LevelCatalog.get(4));
    expect(resumed.restore(loaded.runs['classic/4']), 42000);
    expect(resumed.removed, game.removed);
    expect(resumed.lives, 2);
    expect(resumed.hinted, game.hinted);
    expect(resumed.mistakes, 1);
    final wrongLevel = GameSession(LevelCatalog.get(5));
    expect(wrongLevel.restore(loaded.runs['classic/4']), 0);
    expect(wrongLevel.removed, isEmpty);
  });
  test(
    'streak grants once per day, resets after gap and cycles after seven',
    () {
      final p = PlayerProgress();
      for (var day = 1; day <= 8; day++) {
        final date = DateTime(2026, 10, day);
        expect(p.completeDaily(date, 2), isTrue);
        final balance = p.coins;
        expect(p.completeDaily(date, 3), isFalse);
        expect(p.coins, balance);
      }
      expect(p.streakRewards['2026-10-07'], 100);
      expect(p.streakRewards['2026-10-08'], 20);
      p.completeDaily(DateTime(2026, 10, 10), 3);
      expect(p.streakRewards['2026-10-10'], 20);
      expect(PlayerProgress.fromJson(p.toJson()).coins, p.coins);
    },
  );
  test('coin purchases preserve legacy earnings and cannot double charge', () {
    final p = PlayerProgress.fromJson({
      'completed': [1, 2, 3, 4, 5, 6],
    });
    expect(p.coins, 240);
    expect(p.buyTheme('rose'), isFalse);
    expect(p.buyTheme('amethyst'), isTrue);
    expect(p.coins, 40);
    expect(p.buyTheme('amethyst'), isFalse);
    final loaded = PlayerProgress.fromJson(p.toJson());
    expect(loaded.coins, 40);
    expect(loaded.selectedTheme, 'amethyst');
    expect(loaded.themes, contains('amethyst'));
    expect(loaded.buyTheme('invalid'), isFalse);
  });
}
