import 'dart:async';

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
    required this.progress,
    required this.onComplete,
    required this.onSettingsChanged,
  });
  final int level;
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
  bool blocked = false, paused = false, tutorial = false;
  bool firstCompletion = false;
  final playTime = Stopwatch();
  int lessonStep = 0;
  int practiceMistakes = 0;
  bool get learning => game.puzzle.level <= 3;
  String get lessonTitle => switch (game.puzzle.level) {
    1 => 'Follow the arrow',
    2 => 'Protect your hearts',
    _ => 'Find the right order',
  };
  String get lessonText => switch (game.puzzle.level) {
    1 =>
      game.removed.isEmpty
          ? 'Tap the golden arrow. Its tip points to a clear exit.'
          : 'Lovely! Now clear the other arrows. Follow each arrowhead.',
    2 =>
      lessonStep == 0
          ? 'Try the golden arrow. Another path blocks its exit. This practice tap costs one heart.'
          : lessonStep == 1
          ? 'One heart lost. Clear the golden blocker to open the way. Three mistakes mean restart.'
          : 'The way is open! Clear the remaining paths. Empty space never costs a heart.',
    _ =>
      game.removed.isEmpty
          ? 'Clear the golden arrow first. It opens a route for another arrow.'
          : 'Your turn! Look for an open exit. Use Hint if you need help, or pinch to zoom.',
  };
  void prepareLesson() {
    lessonStep = 0;
    practiceMistakes = 0;
    if (learning) {
      game.hinted = game.puzzle.level == 2 ? 0 : game.puzzle.solution().first;
    }
  }

  bool get busy => active != null;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    game = GameSession(LevelCatalog.get(widget.level));
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
    if (busy || paused || tutorial) return;
    if (game.puzzle.level == 2 && lessonStep < 2 && id != game.hinted) return;
    final result = game.tap(id);
    if (result == TapResult.ignored) return;
    if (game.puzzle.level == 2 &&
        lessonStep == 0 &&
        result == TapResult.blocked) {
      practiceMistakes = 1;
    }
    setState(() {
      active = id;
      blocked = result == TapResult.blocked;
    });
    sound(blocked ? 'blocked' : 'clear');
    animation.duration = Duration(
      milliseconds: MediaQuery.disableAnimationsOf(context)
          ? 80
          : blocked
          ? 440
          : 500,
    );
    try {
      await animation.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    setState(() {
      active = null;
      if (game.puzzle.level == 2 && lessonStep < 2) {
        lessonStep++;
        game.hinted = lessonStep == 1 ? 1 : 0;
      }
    });
    if (game.won) {
      playTime.stop();
      firstCompletion = !widget.progress.completed.contains(game.puzzle.level);
      widget.onComplete(
        game.puzzle.level,
        (3 - game.mistakes + practiceMistakes).clamp(1, 3),
      );
      sound('win');
      setState(() {});
    }
  }

  void restart() => setState(() {
    game.restart();
    active = null;
    blocked = false;
    paused = false;
    firstCompletion = false;
    playTime.reset();
    prepareLesson();
    transform.value = Matrix4.identity();
  });
  void next() => setState(() {
    game = GameSession(LevelCatalog.get(game.puzzle.level + 1));
    active = null;
    blocked = false;
    firstCompletion = false;
    paused = false;
    tutorial = learning;
    playTime.reset();
    prepareLesson();
    transform.value = Matrix4.identity();
  });
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
    if (tutorial || paused || game.won || game.lost) {
      playTime.stop();
    } else {
      playTime.start();
    }
    if (game.won && !busy) {
      return VictoryScreen(
        level: game.puzzle.level,
        stars: (3 - game.mistakes + practiceMistakes).clamp(1, 3),
        moves: game.removed.length + game.mistakes,
        elapsed: playTime.elapsed,
        firstCompletion: firstCompletion,
        onNext: game.puzzle.level < LevelCatalog.count
            ? next
            : () => Navigator.pop(context),
        onReplay: restart,
        onHome: () => Navigator.pop(context),
      );
    }
    return PopScope(
      canPop: !busy,
      child: Scaffold(
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
                                      'LEVEL ${game.puzzle.level.toString().padLeft(2, '0')}  ·  CLASSIC',
                                      style: const TextStyle(
                                        fontFamily: 'ArrowNovaSans',
                                        fontSize: 9,
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
                                          child: Icon(
                                            i < game.lives
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            size: 28,
                                            color: i < game.lives
                                                ? const Color(0xFFF34F6C)
                                                : const Color(0xFF98A8B7),
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
                                      fontSize: 9,
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
                                                'LESSON ${game.puzzle.level} OF 3 · $lessonTitle',
                                                style: const TextStyle(
                                                  fontFamily: 'ArrowNovaSans',
                                                  fontSize: 11,
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
                                        maxScale: 2.5,
                                        panEnabled: !busy && !overlay,
                                        scaleEnabled: !busy && !overlay,
                                        child: ArrowBoard(
                                          game: game,
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
                                          fontSize: 11,
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
                                                  (game.puzzle.level == 2 &&
                                                      lessonStep < 2)
                                              ? null
                                              : () {
                                                  setState(() => game.hint());
                                                },
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
        ? 'Beautifully solved!'
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
                ? 'Lesson ${game.puzzle.level} of 3\n\n$lessonText'
                : won
                ? '${game.puzzle.arrows.length} paths cleared · ${game.mistakes} mistakes\n'
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
                ? (game.puzzle.level < LevelCatalog.count
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
