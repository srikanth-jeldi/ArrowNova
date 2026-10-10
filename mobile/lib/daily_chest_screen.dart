import 'package:flutter/material.dart';

import 'core/ads.dart';
import 'core/progress_store.dart';
import 'game/daily.dart';
import 'game/puzzle.dart';
import 'game_screen.dart';

class DailyChestScreen extends StatefulWidget {
  const DailyChestScreen({
    super.key,
    required this.progress,
    required this.onChanged,
    this.showAd,
    this.now,
  });
  final PlayerProgress progress;
  final VoidCallback onChanged;
  final Future<HintAdResult> Function()? showAd;
  final DateTime Function()? now;
  @override
  State<DailyChestScreen> createState() => _DailyChestScreenState();
}

class _DailyChestScreenState extends State<DailyChestScreen>
    with WidgetsBindingObserver {
  bool busy = false;
  DateTime get today => (widget.now ?? DateTime.now)();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  Future<void> unlock() async {
    if (busy) return;
    setState(() => busy = true);
    var result = HintAdResult.unavailable;
    try {
      result = await (widget.showAd ?? GameAds.instance.showHintAd)();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      busy = false;
      // At midnight, award the new day's chest, not an expired entitlement.
      if (result == HintAdResult.earned) widget.progress.unlockChest(today);
    });
    if (result == HintAdResult.earned) {
      widget.onChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == HintAdResult.unavailable
                ? 'No ad available. Try later or play Classic for free.'
                : 'Ad not completed. Your chest is still locked.',
          ),
        ),
      );
    }
  }

  Future<void> play(int index) async {
    final date = today;
    if (busy || !widget.progress.chestUnlocked(date)) {
      setState(() {});
      return;
    }
    setState(() => busy = true);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          level: 1,
          dailyDate: date,
          chestIndex: index,
          progress: widget.progress,
          onComplete: (_, stars) {
            widget.progress.completeChest(date, index, stars);
            widget.onChanged();
          },
          onSettingsChanged: widget.onChanged,
        ),
      ),
    );
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final date = today;
    final unlocked = widget.progress.chestUnlocked(date);
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Daily Chest')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: Color(0xffefca75),
            ),
            const SizedBox(height: 16),
            Text(dayKey(date), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              unlocked ? 'Five hard puzzles are yours today.' : 'Complete one rewarded ad to unlock all five hard puzzles until local midnight.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!unlocked)
              FilledButton.icon(
                onPressed: busy ? null : unlock,
                icon: const Icon(Icons.ondemand_video),
                label: Text(
                  busy ? 'Opening ad…' : 'Watch ad · unlock 5 puzzles',
                ),
              ),
            const SizedBox(height: 20),
            for (var i = 0; i < 5; i++)
              Card(
                child: ListTile(
                  leading: Icon(
                    unlocked ? Icons.extension_outlined : Icons.lock_outline,
                  ),
                  title: Text('Challenge ${i + 1}'),
                  subtitle: Text(
                    widget.progress.chestStars.containsKey(
                          widget.progress.chestKey(date, i),
                        )
                        ? '${widget.progress.chestStars[widget.progress.chestKey(date, i)]} stars · replay'
                        : 'Hard · ${LevelCatalog.arrowCount(DailyChestCatalog.level(date, i))} arrows',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: unlocked && !busy ? () => play(i) : null,
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Classic and the regular Daily Challenge remain free. No stars are awarded for watching an ad.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
