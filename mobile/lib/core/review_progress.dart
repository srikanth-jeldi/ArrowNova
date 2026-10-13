/// Review attempts are spaced locally even when the store suppresses its UI.
class ReviewProgress {
  ReviewProgress({this.wins = 0, this.lastRequested});
  int wins;
  DateTime? lastRequested;
  static const cooldown = Duration(days: 30);

  void recordWin() => wins = (wins + 1).clamp(0, 3);
  void resetStreak() => wins = 0;

  bool claim(DateTime now) {
    if (wins < 3 ||
        (lastRequested != null && now.difference(lastRequested!) < cooldown)) {
      return false;
    }
    wins = 0;
    lastRequested = now;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'wins': wins,
    'lastRequested': lastRequested?.toIso8601String(),
  };
  factory ReviewProgress.fromJson(dynamic value) {
    final data = value is Map ? value : const {};
    return ReviewProgress(
      wins: data['wins'] is int ? (data['wins'] as int).clamp(0, 3) : 0,
      lastRequested: data['lastRequested'] is String
          ? DateTime.tryParse(data['lastRequested'] as String)
          : null,
    );
  }
}
