import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/core/reminders.dart';
import 'package:arrownova/garden/decor_collection.dart';

void main() {
  test('legacy balance and ad ownership survive shopping and restart', () {
    final p = PlayerProgress.fromJson({
      'completed': List.generate(20, (i) => i + 1),
      'themes': ['crystal', 'amethyst'],
      'dailyReminders': true,
      'homeDecor2D': {
        'level': 1,
        'rooms': {
          '1': {
            'credits': {'decor_1_1': 3},
          },
        },
      },
    });
    expect(p.coins, 600);
    expect(p.reminderLimit, 1);
    const pillow = DecorPiece(1, 4);
    expect(p.buyDecor(pillow), true);
    expect(p.buyDecor(pillow), false);
    expect(p.homeDecor.current.place(pillow), true);
    final r = PlayerProgress.fromJson(p.toJson());
    expect(r.coins, 480);
    expect(r.homeDecor.current.owns(pillow), true);
    expect(r.homeDecor.current.owns(const DecorPiece(1, 1)), true);
    r.homeDecor.level = 2;
    expect(r.homeDecor.current.owns(pillow), false);
    expect(PlayerProgress().buyDecor(pillow), false);
  });
  test('one shield bridges one missed date without fabricated rewards', () {
    var p = PlayerProgress(completed: {1, 2, 3, 4, 5});
    final first = DateTime(2026, 11, 1), third = DateTime(2026, 11, 3);
    p.completeDaily(first, 3);
    expect(p.buyShield(first), true);
    final balance = p.coins;
    expect(p.buyShield(first), false);
    p = PlayerProgress.fromJson(p.toJson());
    expect(p.applyShield(third), true);
    expect(p.applyShield(third), false);
    expect(p.coins, balance);
    expect(p.dailyStars.length, 1);
    expect(p.dailyStreak(third), 1);
    p.completeDaily(third, 3);
    expect(p.dailyStreak(third), 2);
    expect(p.coins, balance + 40 + 30);
    expect(p.shieldBought, isNull);
    p = PlayerProgress.fromJson(p.toJson());
    expect(p.dailyStreak(third), 2);
    expect(p.dailyStreak(DateTime(2026, 11, 5)), 0);
  });
  test('shield does not backfill earlier gaps or save two missed days', () {
    final p = PlayerProgress(completed: {1, 2, 3, 4, 5});
    p.completeDaily(DateTime(2026, 11, 1), 1);
    p.buyShield(DateTime(2026, 11, 4));
    expect(p.applyShield(DateTime(2026, 11, 4)), false);
    p.completeDaily(DateTime(2026, 11, 4), 2);
    p.completeDaily(DateTime(2026, 11, 7), 2);
    expect(p.dailyStreak(DateTime(2026, 11, 7)), 1);
  });
  test('optional reminders honour cap, skipped conditions and quiet hours', () {
    final now = DateTime(2026, 11, 1, 8);
    for (final n in [0, 1, 2, 4]) {
      final slots = reminderPlan(
        now,
        done: false,
        limit: n,
        unfinished: true,
        streak: 3,
      );
      expect(slots.length, n);
      expect(slots.map((s) => s.id).toSet().length, n);
      expect(slots.every((s) => s.at.hour >= 9 && s.at.hour <= 20), true);
    }
    final slots = reminderPlan(
      now,
      done: true,
      limit: 4,
      unfinished: false,
      streak: 3,
    );
    expect(slots.any((s) => s.id == 1), false);
    expect(slots.every((s) => s.at.day > 1), true);
    expect(slots.singleWhere((s) => s.id == 3).repeat, false);
    expect(
      reminderPlan(
        now,
        done: false,
        limit: 4,
        unfinished: true,
        streak: 0,
      ).any((s) => s.id == 3),
      false,
    );
  });
}
