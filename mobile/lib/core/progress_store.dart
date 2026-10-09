import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../game/puzzle.dart';
import '../garden/garden_catalog.dart';

class PlayerProgress {
  PlayerProgress({
    Set<int>? completed,
    Set<String>? owned,
    Map<int, String>? placements,
    Map<int, int>? bestStars,
    this.sound = true,
    this.haptics = true,
  }) : completed = completed ?? {},
       owned = {...?owned, 'lantern'},
       placements = placements ?? {},
       bestStars = bestStars ?? {};
  final Set<int> completed;
  final Set<String> owned;
  final Map<int, String> placements;
  final Map<int, int> bestStars;
  bool sound, haptics;
  int get coins => completed.length * 40;
  int get gardenPoints =>
      completed.length * 10 -
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
