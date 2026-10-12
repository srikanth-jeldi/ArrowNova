import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/core/reminders.dart';
import 'package:arrownova/game/daily.dart';

void main() {
  test(
    'daily boards are deterministic, in bounds and solvable through rotations',
    () {
      for (var i = 0; i < 8; i++) {
        final date = DateTime(2026, 10, 10 + i);
        final puzzle = DailyCatalog.get(date);
        final again = DailyCatalog.get(DateTime(2026, 10, 10 + i, 23));
        expect(
          puzzle.arrows.map((a) => a.cells.toString()).toList(),
          again.arrows.map((a) => a.cells.toString()).toList(),
        );
        expect(
          puzzle.arrows.every((a) => a.cells.every(puzzle.contains)),
          isTrue,
        );
        expect(puzzle.solution().length, puzzle.arrows.length);
      }
    },
  );
  test('daily rewards count once and do not unlock classic levels', () {
    final progress = PlayerProgress();
    final date = DateTime(2026, 10, 10);
    expect(progress.completeDaily(date, 1), isTrue);
    expect(progress.completeDaily(date, 3), isFalse);
    expect(progress.completeDaily(date, 2), isFalse);
    expect(progress.dailyStars[dayKey(date)], 3);
    expect(
      progress.coins,
      60,
    ); // First daily win plus the day-one streak bonus.
    expect(progress.gardenPoints, 10);
    expect(progress.completed, isEmpty);
    expect(progress.nextLevel, 1);
    progress.dailyReminders = true;
    final restored = PlayerProgress.fromJson(progress.toJson());
    expect(restored.dailyStars, progress.dailyStars);
    expect(restored.dailyReminders, isTrue);
  });
  test('streak crosses calendar years and breaks after a missed day', () {
    final progress = PlayerProgress();
    progress.completeDaily(DateTime(2025, 12, 31), 3);
    progress.completeDaily(DateTime(2026, 1, 1), 2);
    expect(progress.dailyStreak(DateTime(2026, 1, 1)), 2);
    expect(progress.dailyStreak(DateTime(2026, 1, 2)), 2);
    expect(progress.dailyStreak(DateTime(2026, 1, 3)), 0);
  });
  test('9, 13, 19 reminders skip elapsed times and completed days', () {
    final now = DateTime(2026, 12, 31, 13);
    expect(nextReminder(now, 9, false), DateTime(2027, 1, 1, 9));
    expect(nextReminder(now, 13, false), DateTime(2027, 1, 1, 13));
    expect(nextReminder(now, 19, false), DateTime(2026, 12, 31, 19));
    for (final hour in [9, 13, 19]) {
      expect(nextReminder(now, hour, true), DateTime(2027, 1, 1, hour));
    }
  });
}
