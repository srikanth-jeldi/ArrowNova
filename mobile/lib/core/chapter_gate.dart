import 'package:flutter/material.dart';

import 'ads.dart';
import 'progress_store.dart';
import '../game/chapters.dart';
import '../game/puzzle.dart';
import '../ui.dart';

Future<bool> ensureChapter(
  BuildContext context,
  PlayerProgress progress,
  int level,
  VoidCallback save, {
  Future<HintAdResult> Function()? showAd,
}) async {
  // Generated continuation has no additional chapter-ad gate.
  if (level > LevelCatalog.count) return progress.unlocked(level);
  final chapter = ChapterCatalog.of(level);
  if (progress.chapterOpen(chapter)) return true;
  if (!progress.chapterEligible(chapter)) return false;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ChapterUnlock(
          progress: progress,
          chapter: chapter,
          save: save,
          showAd: showAd ?? GameAds.instance.showHintAd,
        ),
      ) ??
      false;
}

class _ChapterUnlock extends StatefulWidget {
  const _ChapterUnlock({
    required this.progress,
    required this.chapter,
    required this.save,
    required this.showAd,
  });
  final PlayerProgress progress;
  final int chapter;
  final VoidCallback save;
  final Future<HintAdResult> Function() showAd;
  @override
  State<_ChapterUnlock> createState() => _ChapterUnlockState();
}

class _ChapterUnlockState extends State<_ChapterUnlock> {
  bool busy = false;
  String? error;
  Future<void> unlock() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    var result = HintAdResult.unavailable;
    try {
      result = await widget.showAd();
    } catch (_) {}
    if (!mounted) return;
    if (result == HintAdResult.earned &&
        widget.progress.unlockChapter(widget.chapter)) {
      // Do not stack an interstitial after this rewarded transition.
      widget.progress.levelsSinceAdBreak = 0;
      widget.save();
      Navigator.pop(context, true);
    } else {
      setState(() {
        busy = false;
        error = result == HintAdResult.dismissed
            ? 'Ad not completed. Chapter stays locked.'
            : 'No ad available. Try later; unlocked chapters are still playable.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      backgroundColor: navy,
      icon: const Icon(Icons.auto_awesome, color: gold, size: 40),
      title: Text(
        'Chapter ${widget.chapter} · ${ChapterCatalog.name(widget.chapter)}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Levels ${ChapterCatalog.first(widget.chapter)}–${ChapterCatalog.last(widget.chapter)}\n\nComplete one rewarded ad to unlock this chapter permanently on this device. Replays need no chapter ad.',
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: busy ? null : unlock,
          child: Text(busy ? 'Opening ad…' : 'Watch ad · unlock chapter'),
        ),
      ],
    ),
  );
}
