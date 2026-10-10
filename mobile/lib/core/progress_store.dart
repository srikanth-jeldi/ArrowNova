import '../game/daily.dart';

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../game/puzzle.dart';
import '../garden/garden_catalog.dart';

class PlayerProgress {
  PlayerProgress({
    Set<int>? completed,
    Map<String, int>? dailyStars,
    this.dailyReminders = false,
    Set<String>? owned,
    Map<int, String>? placements,
    Map<int, int>? bestStars,
    this.trainingCompleted = false,
    this.levelsSinceAdBreak = 0,
    this.sound = true,
    this.haptics = true,
  }) : completed = completed ?? {},
       dailyStars = dailyStars ?? {},
       owned = {...?owned, 'lantern'},
       placements = placements ?? {},
       bestStars = bestStars ?? {};
  final Set<int> completed;
  final Map<String, int> dailyStars;
  bool dailyReminders;
  bool completeDaily(DateTime date, int stars) {
    final key = dayKey(date);
    final first = !dailyStars.containsKey(key);
    if (stars > (dailyStars[key] ?? 0)) dailyStars[key] = stars;
    return first;
  }

  int dailyStreak(DateTime today) {
    var date = DateTime(today.year, today.month, today.day);
    if (!dailyStars.containsKey(dayKey(date))) {
      date = DateTime(date.year, date.month, date.day - 1);
    }
    var streak = 0;
    while (dailyStars.containsKey(dayKey(date))) {
      streak++;
      date = DateTime(date.year, date.month, date.day - 1);
    }
    return streak;
  }

  final Set<String> owned;
  final Map<int, String> placements;
  final Map<int, int> bestStars;
  bool sound, haptics;
  bool trainingCompleted;
  int levelsSinceAdBreak;
  void recordAdCompletion() {
    levelsSinceAdBreak = (levelsSinceAdBreak + 1).clamp(0, 3);
  }

  bool consumeAdBreak() {
    if (levelsSinceAdBreak < 3) return false;
    levelsSinceAdBreak = 0;
    return true;
  }

  int get coins => (completed.length + dailyStars.length) * 40;
  int get gardenPoints =>
      (completed.length + dailyStars.length) * 10 -
      gardenItems
          .where((i) => owned.contains(i.id))
          .fold(0, (sum, i) => sum + i.cost);
  bool buy(String id) {
    final items = gardenItems.where((i) => i.id == id);
    if (items.isEmpty) return false;
    final item = items.first;
    if (owned.contains(id) ||
        completed.length < item.unlock ||
        gardenPoints < item.cost) {
      return false;
    }
    return owned.add(id);
  }

  bool place(String id, int slot) {
    if (!owned.contains(id) || slot < 0 || slot > 5) return false;
    placements.removeWhere((key, value) => value == id);
    placements[slot] = id;
    return true;
  }

  int get nextLevel {
    for (var i = 1; i <= LevelCatalog.count; i++) {
      if (!completed.contains(i)) return i;
    }
    return LevelCatalog.count;
  }

  bool unlocked(int level) => level == 1 || completed.contains(level - 1);
  Map<String, Object> toJson() => {
    'completed': completed.toList(),
    'dailyStars': dailyStars,
    'dailyReminders': dailyReminders,
    'trainingCompleted': trainingCompleted,
    'levelsSinceAdBreak': levelsSinceAdBreak,
    'sound': sound,
    'haptics': haptics,
    'owned': owned.toList(),
    'placements': placements.map((key, value) => MapEntry('$key', value)),
    'stars': bestStars.map((key, value) => MapEntry('$key', value)),
  };
  factory PlayerProgress.fromJson(Map<String, dynamic> data) => PlayerProgress(
    completed: (data['completed'] as List? ?? [])
        .whereType<int>()
        .where((n) => n >= 1 && n <= LevelCatalog.count)
        .toSet(),
    dailyReminders: data['dailyReminders'] == true,
    dailyStars: {
      for (final entry
          in (data['dailyStars'] is Map ? data['dailyStars'] as Map : {})
              .entries)
        if (entry.key is String &&
            RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(entry.key) &&
            DateTime.tryParse(entry.key) != null &&
            dayKey(DateTime.parse(entry.key)) == entry.key &&
            entry.value is int &&
            entry.value >= 1 &&
            entry.value <= 3)
          entry.key as String: entry.value as int,
    },
    trainingCompleted: data['trainingCompleted'] == true,
    levelsSinceAdBreak: data['levelsSinceAdBreak'] is int
        ? (data['levelsSinceAdBreak'] as int).clamp(0, 3)
        : 0,
    sound: data['sound'] != false,
    haptics: data['haptics'] != false,
    owned: (data['owned'] as List? ?? [])
        .whereType<String>()
        .where((id) => gardenItems.any((i) => i.id == id))
        .toSet(),
    placements: {
      for (final entry in (data['placements'] as Map? ?? {}).entries)
        if (int.tryParse('${entry.key}') case final int slot
            when slot >= 0 && slot < 6)
          if (entry.value is String &&
              (entry.value == 'lantern' ||
                  (data['owned'] as List? ?? []).contains(entry.value)))
            slot: entry.value as String,
    },
    bestStars: {
      for (final entry in (data['stars'] as Map? ?? {}).entries)
        if (int.tryParse('${entry.key}') case final int level
            when level >= 1 && level <= LevelCatalog.count)
          if (entry.value is int && entry.value >= 1 && entry.value <= 3)
            level: entry.value as int,
    },
  );
}

/// Uses the same secure-storage approach as ChessVerse AuthSessionStore,
/// with an ArrowNova-only namespace and no production account connections.
class ProgressStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'arrownova.progress.v1';
  Future<PlayerProgress> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) return PlayerProgress();
    return PlayerProgress.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> save(PlayerProgress progress) =>
      _storage.write(key: _key, value: jsonEncode(progress.toJson()));
}
