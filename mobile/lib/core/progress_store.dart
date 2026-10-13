import '../game/daily.dart';
import 'review_progress.dart';
import '../game/chapters.dart';

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../game/puzzle.dart';
import '../game/board_themes.dart';
import '../garden/garden_catalog.dart';

class PlayerProgress {
  PlayerProgress({
    Set<int>? completed,
    Set<int>? skipped,
    Set<int>? chapters,
    this.chestDay,
    Map<String, int>? chestStars,
    this.music = true,
    Map<String, int>? dailyStars,
    this.dailyReminders = false,
    Set<String>? owned,
    Map<int, String>? placements,
    Map<int, int>? bestStars,
    this.trainingCompleted = false,
    this.levelsSinceAdBreak = 0,
    this.sound = true,
    this.haptics = true,
    Map<String, Map<String, dynamic>>? runs,
    Map<String, int>? streakRewards,
    Set<String>? themes,
    this.selectedTheme = 'crystal',
    ReviewProgress? review,
  }) : completed = completed ?? {},
       chapters = {
         1,
         ...(chapters ??
             _readChapters({
               'completed': completed?.toList() ?? [],
               'skipped': skipped?.toList() ?? [],
             })),
       },
       skipped = skipped ?? {},
       chestStars = chestStars ?? {},
       dailyStars = dailyStars ?? {},
       owned = {...?owned, 'lantern'},
       placements = placements ?? {},
       bestStars = bestStars ?? {},
       runs = runs ?? {},
       streakRewards = streakRewards ?? {},
       themes = {'crystal', ...?themes},
       review = review ?? ReviewProgress();
  final ReviewProgress review;
  final Map<String, Map<String, dynamic>> runs;
  final Map<String, int> streakRewards;
  final Set<String> themes;
  String selectedTheme;
  bool buyTheme(String id) {
    final matches = boardThemes.where((theme) => theme.id == id);
    if (matches.isEmpty || themes.contains(id) || coins < matches.first.cost) {
      return false;
    }
    themes.add(id);
    selectedTheme = id;
    return true;
  }

  int nextStreakBonus(DateTime date) {
    final yesterday = DateTime(date.year, date.month, date.day - 1);
    final previous = dailyStars.containsKey(dayKey(yesterday))
        ? dailyStreak(yesterday)
        : 0;
    return const [20, 30, 40, 50, 60, 80, 100][previous % 7];
  }

  final Set<int> completed;
  final Set<int> chapters;
  bool chapterOpen(int chapter) => chapters.contains(chapter);
  bool chapterEligible(int chapter) =>
      chapter == 1 ||
      (chapter >= 2 &&
          chapter <= ChapterCatalog.count &&
          (completed.contains(ChapterCatalog.first(chapter) - 1) ||
              skipped.contains(ChapterCatalog.first(chapter) - 1)));
  bool unlockChapter(int chapter) {
    if (!chapterEligible(chapter)) return false;
    return chapters.add(chapter);
  }

  static Set<int> _readChapters(Map<String, dynamic> data) {
    if (data['chapters'] is List) {
      return {
        1,
        ...(data['chapters'] as List).whereType<int>().where(
          (n) => n >= 1 && n <= ChapterCatalog.count,
        ),
      };
    }
    // Existing players keep every chapter already reached before chapter gates.
    var reached = 1;
    for (final n in [
      ...(data['completed'] as List? ?? []),
      ...(data['skipped'] as List? ?? []),
    ].whereType<int>()) {
      if (n >= 1 && n <= LevelCatalog.count) {
        final chapter = ChapterCatalog.of((n + 1).clamp(1, LevelCatalog.count));
        if (chapter > reached) reached = chapter;
      }
    }
    return {for (var c = 1; c <= reached; c++) c};
  }

  final Set<int> skipped;
  String? chestDay;
  final Map<String, int> chestStars;
  bool music;
  bool chestUnlocked(DateTime date) => chestDay == dayKey(date);
  void unlockChest(DateTime date) => chestDay = dayKey(date);
  String chestKey(DateTime date, int index) => '${dayKey(date)}/$index';
  bool completeChest(DateTime date, int index, int stars) {
    if (!chestUnlocked(date) || index < 0 || index >= 5) return false;
    final key = chestKey(date, index);
    final first = !chestStars.containsKey(key);
    if (stars > (chestStars[key] ?? 0)) chestStars[key] = stars.clamp(1, 3);
    return first;
  }

  void skip(int level) {
    if (level >= 1 &&
        level < LevelCatalog.count &&
        !completed.contains(level)) {
      skipped.add(level);
    }
  }

  final Map<String, int> dailyStars;
  bool dailyReminders;
  bool completeDaily(DateTime date, int stars) {
    final key = dayKey(date);
    final first = !dailyStars.containsKey(key);
    if (first) streakRewards[key] = nextStreakBonus(date);
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
    levelsSinceAdBreak = (levelsSinceAdBreak + 1).clamp(0, 2);
  }

  bool consumeAdBreak() {
    if (levelsSinceAdBreak < 2) return false;
    levelsSinceAdBreak = 0;
    return true;
  }

  int get coins =>
      (completed.length + dailyStars.length + chestStars.length) * 40 +
      streakRewards.values.fold<int>(0, (sum, value) => sum + value) -
      boardThemes
          .where((theme) => themes.contains(theme.id))
          .fold<int>(0, (sum, theme) => sum + theme.cost);
  int get gardenPoints =>
      (completed.length + dailyStars.length + chestStars.length) * 10 -
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
      if (!completed.contains(i) && !skipped.contains(i)) return i;
    }
    return LevelCatalog.count;
  }

  bool unlocked(int level) =>
      level == 1 ||
      completed.contains(level - 1) ||
      skipped.contains(level - 1);
  Map<String, Object> toJson() => {
    'runs': runs,
    'streakRewards': streakRewards,
    'themes': themes.toList(),
    'selectedTheme': selectedTheme,
    'review': review.toJson(),
    'completed': completed.toList(),
    'chapters': chapters.toList(),
    'skipped': skipped.toList(),
    'chestDay': chestDay ?? '',
    'chestStars': chestStars,
    'music': music,
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
    review: ReviewProgress.fromJson(data['review']),
    runs: {
      for (final entry
          in (data['runs'] is Map ? data['runs'] as Map : {}).entries.take(20))
        if (entry.key is String && entry.value is Map)
          entry.key as String: Map<String, dynamic>.from(entry.value as Map),
    },
    streakRewards: {
      for (final entry
          in (data['streakRewards'] is Map ? data['streakRewards'] as Map : {})
              .entries)
        if (entry.key is String &&
            DateTime.tryParse(entry.key) != null &&
            entry.value is int &&
            const [20, 30, 40, 50, 60, 80, 100].contains(entry.value))
          entry.key as String: entry.value as int,
    },
    themes: (data['themes'] is List ? data['themes'] as List : [])
        .whereType<String>()
        .where((id) => boardThemes.any((theme) => theme.id == id))
        .toSet(),
    selectedTheme:
        data['selectedTheme'] is String &&
            (data['themes'] is List ? data['themes'] as List : []).contains(
              data['selectedTheme'],
            )
        ? boardTheme(data['selectedTheme']).id
        : 'crystal',
    chapters: _readChapters(data),
    skipped: (data['skipped'] as List? ?? [])
        .whereType<int>()
        .where((n) => n >= 1 && n < LevelCatalog.count)
        .toSet(),
    chestDay: data['chestDay'] is String ? data['chestDay'] as String : null,
    chestStars: {
      for (final entry
          in (data['chestStars'] is Map ? data['chestStars'] as Map : {})
              .entries)
        if (entry.key is String &&
            RegExp(r'^\d{4}-\d{2}-\d{2}/[0-4]$').hasMatch(entry.key) &&
            entry.value is int &&
            entry.value >= 1 &&
            entry.value <= 3)
          entry.key as String: entry.value as int,
    },
    music: data['music'] != false,
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
        ? (data['levelsSinceAdBreak'] as int).clamp(0, 2)
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
  ProgressStore({Future<void> Function(String)? write})
    : _write = write ?? ((value) => _storage.write(key: _key, value: value));
  static const _storage = FlutterSecureStorage();
  static const _key = 'arrownova.progress.v1';
  final Future<void> Function(String) _write;
  String? _pending;
  Future<void>? _writing;
  Future<PlayerProgress> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) return PlayerProgress();
    return PlayerProgress.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  Future<void> save(PlayerProgress progress) {
    // Capture immutable JSON now. While storage is busy, retain only the newest
    // checkpoint so a win is not stuck behind hundreds of obsolete arrow saves.
    _pending = jsonEncode(progress.toJson());
    return _writing ??= _flush();
  }

  Future<void> _flush() async {
    try {
      while (_pending != null) {
        final value = _pending!;
        _pending = null;
        await _write(value);
      }
    } finally {
      _writing = null;
    }
  }
}
