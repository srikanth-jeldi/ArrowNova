import 'dart:async';

import 'package:flutter/material.dart';

import 'core/progress_store.dart';
import 'game/daily.dart';
import 'ui.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({
    super.key,
    required this.progress,
    required this.play,
    required this.enableReminders,
    this.now = DateTime.now,
  });

  final PlayerProgress progress;
  final Future<void> Function(DateTime date) play;
  final Future<bool> Function() enableReminders;
  final DateTime Function() now;

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with WidgetsBindingObserver {
  Timer? clock;
  bool playing = false;
  bool enabling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    clock = Timer.periodic(const Duration(seconds: 15), (_) => setState(() {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  void dispose() {
    clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> playToday() async {
    final today = widget.now();
    if (playing || widget.progress.dailyStars.containsKey(dayKey(today))) {
      setState(() {});
      return;
    }
    setState(() => playing = true);
    try {
      await widget.play(today);
    } finally {
      if (mounted) setState(() => playing = false);
    }
  }

  Future<void> enableReminders() async {
    setState(() => enabling = true);
    var enabled = false;
    try {
      enabled = await widget.enableReminders();
    } catch (_) {
      // The player can retry after enabling notifications in phone Settings.
    }
    if (!mounted) return;
    setState(() => enabling = false);
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Allow ArrowNova notifications in phone Settings and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    final today = widget.now();
    final key = dayKey(today);
    final stars = progress.dailyStars[key];
    final streak = progress.dailyStreak(today);
    final run = progress.runs['daily/$key'];
    final removed = run?['removed'];
    final inProgress = removed is List && removed.isNotEmpty;
    final bonus = stars == null
        ? progress.nextStreakBonus(today)
        : progress.streakRewards[key] ?? 0;
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final minutes = tomorrow.difference(today).inMinutes;
    final nextPuzzle = minutes > 0
        ? '${minutes ~/ 60}h ${minutes % 60}m'
        : '<1 min';
    final labels = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Challenge')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Card(
                  color: const Color(0xFF102A43),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          stars == null
                              ? Icons.calendar_today_rounded
                              : Icons.emoji_events_rounded,
                          color: gold,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          labels.formatFullDate(today),
                          style: const TextStyle(color: muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stars != null
                              ? 'Today’s puzzle complete'
                              : inProgress
                              ? 'Your puzzle is saved'
                              : 'Today’s puzzle',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          stars != null
                              ? '$stars / 3 stars · +${PlayerProgress.coinsPerFirstWin + bonus} coins earned'
                              : 'Win 40 coins + $bonus streak bonus',
                        ),
                        const SizedBox(height: 18),
                        if (stars == null)
                          GoldButton(
                            label: inProgress
                                ? 'Resume puzzle'
                                : 'Play daily puzzle',
                            icon: Icons.play_arrow_rounded,
                            onPressed: playing ? null : playToday,
                          )
                        else ...[
                          Text(
                            'Next puzzle in $nextPuzzle',
                            style: const TextStyle(
                              color: gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tomorrow’s streak bonus: +${progress.nextStreakBonus(tomorrow)} coins',
                            style: const TextStyle(color: muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '$streak-day streak',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  streak == 0
                      ? 'Clear today’s puzzle to start a streak.'
                      : 'Clear one puzzle each day to keep your streak going.',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var offset = 6; offset >= 0; offset--)
                      Expanded(
                        child: _day(
                          context,
                          DateTime(today.year, today.month, today.day - offset),
                          offset == 0,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!progress.dailyReminders)
                  OutlinedButton.icon(
                    onPressed: enabling ? null : enableReminders,
                    icon: const Icon(Icons.notifications_outlined),
                    label: Text(enabling ? 'Enabling…' : 'Remind me to play'),
                  )
                else
                  const ListTile(
                    leading: Icon(Icons.notifications_active_outlined),
                    title: Text('Puzzle reminders are on'),
                    subtitle: Text('Change reminder frequency in Settings.'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _day(BuildContext context, DateTime date, bool today) {
    final key = dayKey(date);
    final cleared = widget.progress.dailyStars.containsKey(key);
    final protected = widget.progress.protectedDays.contains(key);
    final names = MaterialLocalizations.of(context).narrowWeekdays;
    return Semantics(
      label:
          '${MaterialLocalizations.of(context).formatMediumDate(date)}, '
          '${cleared
              ? 'completed'
              : protected
              ? 'protected by shield'
              : today
              ? 'today'
              : 'missed'}',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            names[date.weekday % 7],
            style: TextStyle(color: today ? gold : muted),
          ),
          const SizedBox(height: 4),
          Icon(
            cleared
                ? Icons.check_circle
                : protected
                ? Icons.shield
                : Icons.radio_button_unchecked,
            color: cleared || protected || today ? gold : muted,
            size: 22,
          ),
        ],
      ),
    );
  }
}
