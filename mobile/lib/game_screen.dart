import 'game/daily.dart';
import 'core/ads.dart';

import 'dart:async';

import 'core/chapter_gate.dart';
import 'game/chapters.dart';

import 'package:flutter/material.dart';

import 'core/progress_store.dart';
import 'core/feedback_service.dart';
import 'game/puzzle.dart';
import 'game/board.dart';
import 'ui.dart';
import 'victory_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    this.startTraining = false,
    this.showHintAd,
    this.dailyDate,
    this.chestIndex,
    required this.progress,
    required this.onComplete,
    required this.onSettingsChanged,
  });
  final int level;
  final bool startTraining;
  final DateTime? dailyDate;
  final int? chestIndex;
  final Future<HintAdResult> Function()? showHintAd;
  final PlayerProgress progress;
  final void Function(int level, int stars) onComplete;
  final VoidCallback onSettingsChanged;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late GameSession game;
  late final AnimationController animation;
  final feedback = FeedbackService();
  final transform = TransformationController();
  int? active;
  int? queuedTap;
  bool blocked = false, paused = false, tutorial = false;
  bool firstCompletion = false;
  bool celebrating = false;
  bool changingLevel = false;
  bool hintFlow = false;
  final playTime = Stopwatch();
  int lessonStep = 0;
  int practiceMistakes = 0;
  int trainingRound = 0;
  bool get learning => trainingRound > 0;
  String get lessonTitle => switch (game.puzzle.level) {
    1 => 'Follow the arrow',
    2 => 'Protect your hearts',
    _ => 'Find the right order',
  };
  String get lessonText {
    if (trainingRound == 2 && lessonStep == 0) {
      return 'Tap the golden arrow pointing RIGHT. Its exit is blocked: watch it bump and lose one practice heart.';
    }
    final id = game.hinted;
    if (id == null) return 'Well done! You cleared every arrow.';
    final d = game.puzzle.arrows.firstWhere((a) => a.id == id).direction;
    final direction = d.x > 0
        ? 'RIGHT'
        : d.x < 0
        ? 'LEFT'
        : d.y > 0
        ? 'DOWN'
        : 'UP';
    return trainingRound == 2 && lessonStep == 1
        ? 'Clear this golden blocker $direction first. Then the blocked arrow can leave. Three wrong taps restart a real puzzle.'
        : 'Tap the golden arrow. Watch it slide $direction through the clear exit.';
  }

  void prepareLesson() {
    lessonStep = 0;
    practiceMistakes = 0;
    if (learning) {
      game.hinted = game.puzzle.level == 2 ? 0 : game.puzzle.solution().first;
    }
  }

  bool get busy => active != null || celebrating || hintFlow;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    trainingRound = widget.startTraining ? 1 : 0;
    game = GameSession(
      learning
          ? TrainingCatalog.get(1)
          : widget.dailyDate != null
          ? widget.chestIndex != null
                ? DailyChestCatalog.get(widget.dailyDate!, widget.chestIndex!)
                : DailyCatalog.get(widget.dailyDate!)
          : LevelCatalog.get(widget.level),
    );
    tutorial = learning;
    prepareLesson();
    animation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 450),
        )..addListener(() {
          if (mounted) setState(() {});
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(feedback.stop());
    if (state != AppLifecycleState.resumed &&
        mounted &&
        !game.won &&
        !game.lost) {
      setState(() => paused = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    animation.dispose();
    playTime.stop();
    transform.dispose();
    feedback.dispose();
    super.dispose();
  }

  void sound(String event) => unawaited(
    feedback.play(
      event,
      sound: widget.progress.sound,
      haptics: widget.progress.haptics,
    ),
  );

  Future<void> tap(int? id) async {
    if (paused || tutorial) return;
    if (busy) {
      // Buffer one safe next move during an exit, never repeat a mistake or
      // charge a heart for a tap made while another arrow was moving.
      if (active != null &&
          !blocked &&
          !learning &&
          !celebrating &&
          !hintFlow &&
          id != null &&
          game.puzzle.canExit(id, game.removed)) {
        queuedTap ??= id;
      }
      return;
    }
    if (learning && id != game.hinted) return;
    final result = game.tap(id);
    if (result == TapResult.ignored) return;
    if (learning &&
        game.puzzle.level == 2 &&
        lessonStep == 0 &&
        result == TapResult.blocked) {
      practiceMistakes = 1;
    }
    setState(() {
      active = id;
      blocked = result == TapResult.blocked;
    });
    sound(blocked ? (game.lost ? 'lost' : 'blocked') : 'clear');
    animation.duration = Duration(
      milliseconds: MediaQuery.disableAnimationsOf(context)
          ? 80
          : blocked
          ? 440
          : 300,
    );
    try {
      await animation.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    if (game.won && !learning && !MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        celebrating = true;
        active = null;
        transform.value = Matrix4.identity();
      });
      animation.duration = const Duration(milliseconds: 650);
      try {
        await animation.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
      if (!mounted) return;
    }
    setState(() {
      celebrating = false;
      active = null;
      if (learning && game.puzzle.level == 2 && lessonStep < 2) {
        lessonStep++;
        game.hinted = lessonStep == 1 ? 1 : 0;
      } else if (learning) {
        final remaining = game.puzzle.solution(game.removed);
        game.hinted = remaining.isEmpty ? null : remaining.first;
      }
    });
    if (game.won) {
      playTime.stop();
      if (learning) {
        sound('win');
        return;
      }
      firstCompletion = widget.chestIndex != null
          ? !widget.progress.chestStars.containsKey(
              widget.progress.chestKey(widget.dailyDate!, widget.chestIndex!),
            )
          : widget.dailyDate != null
          ? !widget.progress.dailyStars.containsKey(dayKey(widget.dailyDate!))
          : !widget.progress.completed.contains(game.puzzle.level);
      widget.onComplete(
        game.puzzle.level,
        (3 - game.mistakes + practiceMistakes).clamp(1, 3),
      );
      sound('win');
      setState(() {});
    }
    final nextTap = queuedTap;
    queuedTap = null;
    if (!game.won && !game.lost && nextTap != null) await tap(nextTap);
  }

  void restart() => setState(() {
    queuedTap = null;
    unawaited(feedback.stop());
    game.restart();
    active = null;
    blocked = false;
    paused = false;
    firstCompletion = false;
    playTime.reset();
    prepareLesson();
    transform.value = Matrix4.identity();
  });
  Future<void> next() async {
    if (changingLevel) return;
    changingLevel = true;
    await feedback.stop();
    if (!mounted) return;
    if (!learning &&
        !await ensureChapter(
          context,
          widget.progress,
          game.puzzle.level + 1,
          widget.onSettingsChanged,
          showAd: widget.showHintAd,
        )) {
      changingLevel = false;
      return;
    }
    if (!mounted) return;
    if (!learning && widget.progress.consumeAdBreak()) {
      widget.onSettingsChanged();
      await GameAds.instance.showAtBreak();
    }
    if (!mounted) return;
    changingLevel = false;
    advanceLevel();
  }

  void advanceLevel() => setState(() {
    unawaited(feedback.stop());
    if (learning) {
      if (trainingRound == 1) {
        trainingRound = 2;
        game = GameSession(TrainingCatalog.get(2));
      } else {
        trainingRound = 0;
        widget.progress.trainingCompleted = true;
        widget.onSettingsChanged();
        game = GameSession(LevelCatalog.get(widget.level));
      }
    } else {
      game = GameSession(LevelCatalog.get(game.puzzle.level + 1));
    }
    active = null;
    blocked = false;
    firstCompletion = false;
    paused = false;
    tutorial = learning;
    playTime.reset();
    prepareLesson();
    transform.value = Matrix4.identity();
  });
  Future<void> requestHint() async {
    if (busy || paused || tutorial || game.won || game.lost) return;
    if (learning) {
      setState(() => game.hint());
      return;
    }
    if (game.hinted != null && !game.removed.contains(game.hinted)) return;
    setState(() => hintFlow = true);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: navy,
        title: const Text('Need a hint?'),
        content: const Text(
          'Watch an ad to highlight one safe arrow. The hint is awarded when the ad confirms your reward.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Watch ad for a hint'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    var result = HintAdResult.dismissed;
    if (accepted == true) {
      try {
        result = await (widget.showHintAd ?? GameAds.instance.showHintAd)();
      } catch (_) {
        result = HintAdResult.unavailable;
      }
    }
    if (!mounted) return;
    setState(() {
      hintFlow = false;
      if (result == HintAdResult.earned) game.hint();
    });
    if (accepted == true && result != HintAdResult.earned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == HintAdResult.unavailable
                ? 'No ad available right now. Keep playing or try again later.'
                : 'No reward earned this time. You can keep playing.',
          ),
        ),
      );
    }
  }

  Future<void> requestSkip() async {
    if (busy ||
        paused ||
        learning ||
        tutorial ||
        game.won ||
        widget.dailyDate != null ||
        game.puzzle.level >= LevelCatalog.count) {
      return;
    }
    setState(() => hintFlow = true);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Skip this level?'),
        content: Text(
          'Complete a rewarded ad to unlock the next Classic level. This level stays available to replay. Skipping gives no stars, coins or garden points.${game.puzzle.level % ChapterCatalog.size == 0 ? ' This ad also unlocks the next chapter.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Watch ad to skip'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    var result = HintAdResult.dismissed;
    if (accepted == true) {
      try {
        result = await (widget.showHintAd ?? GameAds.instance.showHintAd)();
      } catch (_) {
        result = HintAdResult.unavailable;
      }
    }
    if (!mounted) return;
    setState(() => hintFlow = false);
    if (result == HintAdResult.earned) {
      widget.progress.skip(game.puzzle.level);
      if (game.puzzle.level % ChapterCatalog.size == 0) {
        widget.progress.unlockChapter(ChapterCatalog.of(game.puzzle.level + 1));
        widget.progress.levelsSinceAdBreak = 0;
      }
      widget.onSettingsChanged();
      advanceLevel();
    } else if (accepted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No reward earned. This level has not been skipped.'),
        ),
      );
    }
  }

  void requestRestart() {
    setState(() => paused = true);
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: navy,
        title: const Text('Restart this puzzle?'),
        content: const Text(
          'This board resets. You get all three hearts back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (!mounted) return;
      if (confirmed == true) {
        restart();
      } else {
        setState(() => paused = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final overlay = tutorial || paused || (!busy && (game.won || game.lost));
    if (tutorial || paused || hintFlow || game.won || game.lost) {
      playTime.stop();
    } else {
      playTime.start();
    }
    if (game.won && !busy && !learning) {
      return VictoryScreen(
        level: game.puzzle.level,
        stars: (3 - game.mistakes + practiceMistakes).clamp(1, 3),
        moves: game.removed.length + game.mistakes,
        elapsed: playTime.elapsed,
        firstCompletion: firstCompletion,
        totalCoins: widget.progress.coins,
        dailyLabel: widget.dailyDate != null
            ? '${dayKey(widget.dailyDate!)}${widget.chestIndex != null ? ' · CHEST ${widget.chestIndex! + 1}' : ''}'
            : null,
        onNext:
            widget.dailyDate == null && game.puzzle.level < LevelCatalog.count
            ? next
            : () => Navigator.pop(context),
        onReplay: restart,
        onHome: () => Navigator.pop(context),
      );
    }
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        bottomNavigationBar: learning ? null : const GameBanner(),
        body: Atmosphere(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 13),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Back to home',
                                onPressed: busy
                                    ? null
                                    : () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: gold,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'ArrowNova',
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: gold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      learning
                                          ? 'PRACTICE $trainingRound / 2'
                                          : widget.dailyDate != null
                                          ? '${widget.chestIndex != null ? 'CHEST ${widget.chestIndex! + 1}/5' : 'DAILY'} · ${dayKey(widget.dailyDate!)}'
                                          : 'LEVEL ${game.puzzle.level.toString().padLeft(2, '0')}  ·  ${LevelCatalog.isHard(game.puzzle.level) ? 'HARD' : 'CLASSIC'}',
                                      style: const TextStyle(
                                        fontFamily: 'ArrowNovaSans',
                                        fontSize: 12,
                                        letterSpacing: 2,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Pause',
                                onPressed: busy || overlay
                                    ? null
                                    : () => setState(() => paused = true),
                                icon: const Icon(
                                  Icons.pause_rounded,
                                  color: gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F7),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFF90AEC3),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x50000000),
                                  blurRadius: 25,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(29),
                              child: Column(
                                children: [
                                  const SizedBox(height: 18),
                                  Semantics(
                                    label: '${game.lives} hearts remaining',
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        3,
                                        (i) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Icon(
                                                i < game.lives
                                                    ? Icons.favorite_rounded
                                                    : Icons
                                                          .favorite_border_rounded,
                                                size: 28,
                                                color: i < game.lives
                                                    ? const Color(0xFFF34F6C)
                                                    : const Color(0xFF98A8B7),
                                              ),
                                              if (busy &&
                                                  blocked &&
                                                  i == game.lives &&
                                                  !MediaQuery.disableAnimationsOf(
                                                    context,
                                                  ))
                                                Opacity(
                                                  opacity: 1 - animation.value,
                                                  child: Transform.translate(
                                                    offset: Offset(
                                                      0,
                                                      -14 * animation.value,
                                                    ),
                                                    child: Transform.scale(
                                                      scale:
                                                          1 +
                                                          .35 * animation.value,
                                                      child: const Icon(
                                                        Icons.favorite_rounded,
                                                        size: 28,
                                                        color: Color(
                                                          0xFFF34F6C,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  Text(
                                    '${game.removed.length} / ${game.puzzle.arrows.length} PATHS CLEARED',
                                    style: const TextStyle(
                                      fontFamily: 'ArrowNovaSans',
                                      fontSize: 12,
                                      letterSpacing: 1.6,
                                      color: Color(0xFF647C8F),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      28,
                                      13,
                                      28,
                                      2,
                                    ),
                                    child: LinearProgressIndicator(
                                      value:
                                          game.removed.length /
                                          game.puzzle.arrows.length,
                                      minHeight: 3,
                                      borderRadius: BorderRadius.circular(3),
                                      color: const Color(0xFF218DCA),
                                      backgroundColor: const Color(0xFFE0E8EB),
                                    ),
                                  ),
                                  if (learning)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        10,
                                        20,
                                        0,
                                      ),
                                      child: Semantics(
                                        liveRegion: true,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF1D4),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                'PRACTICE $trainingRound OF 2 · $lessonTitle',
                                                style: const TextStyle(
                                                  fontFamily: 'ArrowNovaSans',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: navy,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                lessonText,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontFamily: 'ArrowNovaSans',
                                                  fontSize: 12,
                                                  height: 1.4,
                                                  color: navy,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      child: InteractiveViewer(
                                        transformationController: transform,
                                        minScale: 1,
                                        maxScale: 5,
                                        panEnabled: !busy && !overlay,
                                        scaleEnabled: !busy && !overlay,
                                        child: ArrowBoard(
                                          game: game,
                                          celebration: celebrating
                                              ? animation.value
                                              : 0,
                                          showGuide:
                                              learning && !busy && !overlay,
                                          onTap: tap,
                                          activeId: active,
                                          blocked: blocked,
                                          progress: animation.value,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 25,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      child: Text(
                                        busy && blocked
                                            ? 'Path blocked · one heart lost'
                                            : game.hinted != null
                                            ? 'Follow the golden arrow'
                                            : 'Tap a clear path  ·  Pinch to zoom',
                                        key: ValueKey(busy && blocked),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: busy && blocked
                                              ? const Color(0xFFC24055)
                                              : const Color(0xFF687F90),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      8,
                                      18,
                                      18,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        BoardControl(
                                          icon: Icons.restart_alt,
                                          label: 'Restart',
                                          onTap: busy || overlay
                                              ? null
                                              : requestRestart,
                                        ),
                                        BoardControl(
                                          icon: Icons.lightbulb_outline,
                                          label: 'Hint',
                                          onTap:
                                              busy ||
                                                  overlay ||
                                                  (learning &&
                                                      game.puzzle.level == 2 &&
                                                      lessonStep < 2)
                                              ? null
                                              : requestHint,
                                        ),
                                        BoardControl(
                                          icon: widget.progress.sound
                                              ? Icons.volume_up_outlined
                                              : Icons.volume_off_outlined,
                                          label: 'Sound',
                                          onTap: () {
                                            setState(
                                              () => widget.progress.sound =
                                                  !widget.progress.sound,
                                            );
                                            widget.onSettingsChanged();
                                          },
                                        ),
                                        if (!learning &&
                                            widget.dailyDate == null &&
                                            game.puzzle.level <
                                                LevelCatalog.count)
                                          BoardControl(
                                            icon: Icons.skip_next_outlined,
                                            label: 'Skip',
                                            onTap: busy || overlay
                                                ? null
                                                : requestSkip,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (overlay)
                      Positioned.fill(
                        child: ColoredBox(
                          color: const Color(0x99041729),
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(26),
                              child: buildOverlay(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildOverlay() {
    final won = game.won && !busy;
    final lost = game.lost && !busy;
    final title = tutorial
        ? lessonTitle
        : won
        ? (learning ? 'Practice complete!' : 'Beautifully solved!')
        : lost
        ? 'No hearts left'
        : 'A quiet moment';
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173C59), navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: gold.withValues(alpha: .7)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tutorial
                ? Icons.route
                : won
                ? Icons.auto_awesome
                : lost
                ? Icons.favorite_border
                : Icons.pause_circle_outline,
            size: 49,
            color: gold,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 27, color: ice),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            tutorial
                ? 'Practice $trainingRound of 2\n\n$lessonText'
                : won
                ? learning
                      ? 'Well done! Practice is separate from your levels and rewards.'
                      : '${game.puzzle.arrows.length} paths cleared · ${game.mistakes} mistakes\n'
                            '${firstCompletion ? '+40 coins  ·  +10 garden points' : 'A lovely replay. First-win rewards already earned.'}'
                : lost
                ? 'Try this puzzle again with 3 hearts.\nYour completed levels are safe.'
                : 'Take your time. Your puzzle will be here.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.7, fontSize: 13),
          ),
          const SizedBox(height: 25),
          GoldButton(
            label: tutorial
                ? "Let's play"
                : won
                ? (learning
                      ? (trainingRound == 1
                            ? 'Practice round 2'
                            : 'Start Level ${widget.level}')
                      : game.puzzle.level < LevelCatalog.count
                      ? 'Next level'
                      : 'Journey complete')
                : lost
                ? 'Restart level'
                : 'Resume',
            onPressed: tutorial
                ? () => setState(() => tutorial = false)
                : won
                ? (game.puzzle.level < LevelCatalog.count
                      ? next
                      : () => Navigator.pop(context))
                : lost
                ? restart
                : () => setState(() => paused = false),
          ),
          if (!tutorial) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to home', style: TextStyle(color: muted)),
            ),
          ],
        ],
      ),
    );
  }
}
