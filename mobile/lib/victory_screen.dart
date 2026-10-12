import 'dart:math';

import 'package:flutter/material.dart';

import 'game/puzzle.dart';
import 'ui.dart';

class VictoryScreen extends StatelessWidget {
  const VictoryScreen({
    super.key,
    required this.level,
    this.dailyLabel,
    required this.stars,
    required this.moves,
    required this.elapsed,
    required this.firstCompletion,
    required this.totalCoins,
    this.streakBonus = 0,
    this.allowReplay = true,
    required this.onNext,
    required this.onReplay,
    required this.onHome,
  });
  final int level, stars, moves, totalCoins;
  final int streakBonus;
  final bool allowReplay;
  final String? dailyLabel;
  final Duration elapsed;
  final bool firstCompletion;
  final VoidCallback onNext, onReplay, onHome;

  @override
  Widget build(BuildContext context) {
    final time =
        '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: SizedBox(
                  height: max(730, box.maxHeight),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/art/victory-garden.webp',
                        fit: BoxFit.cover,
                        cacheWidth: 1080,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x65051B3D),
                              Color(0x00051B3D),
                              Color(0x00051B3D),
                              Color(0xCC062449),
                            ],
                            stops: [0, .29, .58, .85],
                          ),
                        ),
                      ),
                      const Positioned.fill(
                        child: IgnorePointer(child: VictoryFireworks()),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                        child: Column(
                          children: [
                            const Text(
                              'ArrowNova',
                              style: TextStyle(
                                color: Color(0xFF9DEBFF),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Beautifully solved!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'ArrowNovaSans',
                                color: Colors.white,
                                fontSize: 29,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF063D72),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            VictoryPraise(stars: stars),
                            // Give the tree canopy breathing room without
                            // moving the artwork or the bottom controls.
                            StarCelebration(stars: stars),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xF5FFFFFF),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFE2D6BB),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22071B33),
                                    blurRadius: 12,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  _stat(Icons.alt_route, '$moves', 'Moves'),
                                  _stat(Icons.timer_outlined, time, 'Time'),
                                  _stat(
                                    Icons.toll,
                                    firstCompletion
                                        ? '+${40 + streakBonus}'
                                        : '+0',
                                    'Earned',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Total coins: $totalCoins',
                              style: const TextStyle(
                                fontFamily: 'ArrowNovaSans',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xE6E6EEF1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                firstCompletion
                                    ? (level % 50 == 0
                                          ? 'Garden milestone! +10 points saved'
                                          : '+10 garden points saved')
                                    : 'Rewards already collected',
                                style: const TextStyle(
                                  fontFamily: 'ArrowNovaSans',
                                  fontSize: 12,
                                  color: navy,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GoldButton(
                              label: dailyLabel != null
                                  ? 'Back to home'
                                  : level < LevelCatalog.count
                                  ? 'Next level'
                                  : 'Journey complete',
                              icon: Icons.chevron_right,
                              onPressed: onNext,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (allowReplay)
                                  Expanded(
                                    child: _action(
                                      'Replay',
                                      Icons.replay,
                                      onReplay,
                                    ),
                                  ),
                                if (allowReplay) const SizedBox(width: 12),
                                Expanded(
                                  child: _action(
                                    'Home',
                                    Icons.home_rounded,
                                    onHome,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              dailyLabel != null
                                  ? 'DAILY $dailyLabel COMPLETE'
                                  : 'LEVEL ${level.toString().padLeft(2, '0')} COMPLETE',
                              style: const TextStyle(
                                fontFamily: 'ArrowNovaSans',
                                color: Color(0xFFDBF6FF),
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Expanded(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: navy, size: 18),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'ArrowNovaSans',
                  color: navy,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'ArrowNovaSans',
            color: Color(0xFF51687C),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
  Widget _action(String text, IconData icon, VoidCallback action) =>
      FilledButton.icon(
        onPressed: action,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: const TextStyle(fontFamily: 'ArrowNovaSans', fontSize: 17),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xF2FFFFFF),
          foregroundColor: navy,
          minimumSize: const Size(0, 44),
          side: const BorderSide(color: Color(0xFFD4DDE2)),
        ),
      );
}

/// A brief, non-blocking reaction in the existing subtitle space.
class VictoryPraise extends StatefulWidget {
  const VictoryPraise({super.key, required this.stars});
  final int stars;

  @override
  State<VictoryPraise> createState() => _VictoryPraiseState();
}

class _VictoryPraiseState extends State<VictoryPraise>
    with SingleTickerProviderStateMixin {
  late final AnimationController reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  );
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      reaction.stop();
      reaction.value = 1;
    } else if (!started) {
      reaction.forward();
    }
    started = true;
  }

  @override
  void didUpdateWidget(covariant VictoryPraise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stars != widget.stars &&
        !MediaQuery.disableAnimationsOf(context)) {
      reaction.forward(from: 0);
    }
  }

  @override
  void dispose() {
    reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: reaction,
        builder: (context, _) {
          final seconds = reaction.value * 3.8;
          final fadeIn = ((seconds - 1.6) / .25).clamp(0.0, 1.0);
          final fadeOut = ((3.8 - seconds) / .4).clamp(0.0, 1.0);
          final opacity = min(fadeIn, fadeOut);
          final pulse = sin(max(0.0, seconds - 1.6) * pi * 6);
          final (symbol, label) = switch (widget.stars) {
            3 => ('', 'Perfect!'),
            2 => ('👍', 'Well done!'),
            _ => ('✨', 'Nice solve!'),
          };
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1 - opacity,
                child: const Text(
                  'PUZZLES GROW HERE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'ArrowNovaSans',
                    color: Color(0xFFDBF6FF),
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (opacity > 0)
                Positioned(
                  top: widget.stars == 3 ? 0 : -7,
                  child: Opacity(
                    key: const ValueKey('victory-praise'),
                    opacity: opacity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.stars != 3)
                          ExcludeSemantics(
                            child: Transform.rotate(
                              angle: widget.stars == 3 ? pulse * .1 : 0,
                              child: Transform.scale(
                                scale: 1 + pulse * .07,
                                child: Text(
                                  symbol,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          ),
                        if (widget.stars != 3) const SizedBox(width: 7),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFE7A5),
                            shadows: [Shadow(color: navy, blurRadius: 5)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

/// A finite celebration behind the controls; never intercepts player input.
class VictoryFireworks extends StatefulWidget {
  const VictoryFireworks({super.key});
  @override
  State<VictoryFireworks> createState() => _VictoryFireworksState();
}

class _VictoryFireworksState extends State<VictoryFireworks>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      animation.stop();
      animation.value = 1;
    } else if (!started) {
      animation.forward();
    }
    started = true;
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(painter: _FireworksPainter(animation)),
  );
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;
  @override
  void paint(Canvas canvas, Size size) {
    final seconds = animation.value * 3.6;
    const centers = [Offset(.22, .32), Offset(.78, .39), Offset(.5, .29)];
    const colors = [Color(0xffeeb84f), Color(0xff22b9ef), Color(0xffe989af)];
    for (var burst = 0; burst < 3; burst++) {
      // Launch and burst times match the synthesized victory track.
      final age = seconds - (.55 + burst * .65);
      final origin = Offset(
        centers[burst].dx * size.width,
        centers[burst].dy * size.height,
      );
      if (age >= -.4 && age < 0) {
        final ascent = -age / .4;
        final tip = origin + Offset(0, ascent * size.height * .25);
        canvas.drawLine(
          tip,
          tip + const Offset(0, 20),
          Paint()
            ..color = colors[burst].withValues(alpha: .7)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
      if (age < 0 || age >= 1.65) continue;
      final t = age / 1.65;
      final radius = size.width * .27 * (1 - pow(1 - t, 3));
      final fade = (1 - t) * .9;
      for (var i = 0; i < 32; i++) {
        final angle = i * pi * 2 / 32 + burst;
        final direction = Offset(cos(angle), sin(angle));
        final distance = radius * (.65 + (i % 5) * .08);
        final point = origin + direction * distance + Offset(0, 48 * t * t);
        final paint = Paint()
          ..color = colors[(burst + i % 2) % 3].withValues(alpha: fade)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(point - direction * (4 + 8 * (1 - t)), point, paint);
        if (i.isEven) {
          canvas.drawCircle(
            point,
            1.7 * (1 - t),
            Paint()..color = const Color(0xffffefb6).withValues(alpha: fade),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _GoldStar extends CustomPainter {
  _GoldStar(this.earned);
  final bool earned;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * .46;
    final points = List.generate(10, (i) {
      final angle = -pi / 2 + i * pi / 5;
      final r = i.isEven ? radius : radius * .46;
      return center + Offset(cos(angle), sin(angle)) * r;
    });
    final outline = Path()..addPolygon(points, true);
    canvas.drawShadow(outline, const Color(0x805D3C0C), 5, true);
    for (var i = 0; i < 10; i++) {
      final facet = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(points[i].dx, points[i].dy)
        ..lineTo(points[(i + 1) % 10].dx, points[(i + 1) % 10].dy)
        ..close();
      canvas.drawPath(
        facet,
        Paint()
          ..color = earned
              ? [
                  const Color(0xFFFFEEAC),
                  const Color(0xFFD29B35),
                  const Color(0xFFFFD776),
                  const Color(0xFFAA711C),
                ][i % 4]
              : const Color(0xFFCDD4D8),
      );
    }
    canvas.drawPath(
      outline,
      Paint()
        ..color = earned ? const Color(0xFFFFE8A0) : const Color(0xFFB2BEC7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _GoldStar oldDelegate) =>
      oldDelegate.earned != earned;
}

class StarCelebration extends StatefulWidget {
  const StarCelebration({super.key, required this.stars});
  final int stars;
  @override
  State<StarCelebration> createState() => _StarCelebrationState();
}

class _StarCelebrationState extends State<StarCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      reveal.value = 1;
    } else if (!started) {
      reveal.forward();
    }
    started = true;
  }

  @override
  void didUpdateWidget(covariant StarCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stars != widget.stars) {
      if (MediaQuery.disableAnimationsOf(context)) {
        reveal.value = 1;
      } else {
        reveal.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${widget.stars} of 3 stars earned',
    child: SizedBox(
      width: 300,
      height: 128,
      child: AnimatedBuilder(
        animation: reveal,
        builder: (_, _) => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (widget.stars == 3)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey('perfect-star-burst'),
                    painter: _StarBurst(reveal.value),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final earned = i < widget.stars;
                final phase = ((reveal.value - (.06 + i * .19)) / .25).clamp(
                  0.0,
                  1.0,
                );
                final scale = Curves.easeOutBack.transform(phase);
                final size = Size.square(i == 1 ? 84 : 66);
                return Padding(
                  padding: EdgeInsets.only(top: i == 1 ? 0 : 22),
                  child: Stack(
                    children: [
                      CustomPaint(size: size, painter: _GoldStar(false)),
                      if (earned)
                        Opacity(
                          opacity: phase.clamp(0.0, 1.0),
                          child: Transform.rotate(
                            angle: (1 - phase) * (i.isEven ? -.22 : .22),
                            child: Transform.scale(
                              key: ValueKey('earned-star-$i'),
                              scale: max(.01, scale),
                              child: CustomPaint(
                                size: size,
                                painter: _GoldStar(true),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StarBurst extends CustomPainter {
  _StarBurst(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final t = ((progress - .67) / .33).clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return;
    final center = Offset(size.width / 2, size.height * .45);
    for (var i = 0; i < 38; i++) {
      final angle = i * 2.39996;
      final distance = (30 + (i % 7) * 12) * Curves.easeOut.transform(t);
      final point =
          center +
          Offset(
            cos(angle) * distance,
            sin(angle) * distance * .65 + 35 * t * t,
          );
      final paint = Paint()
        ..color = [
          const Color(0xFFFFCF52),
          const Color(0xFFFFEAAC),
          const Color(0xFF42CFFF),
        ][i % 3].withValues(alpha: (1 - t) * .95);
      final r = (2 + i % 3) * (1 - t * .4);
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + t * 2);
      canvas.drawPath(
        Path()
          ..moveTo(0, -r * 1.6)
          ..lineTo(r * .5, 0)
          ..lineTo(0, r * 1.6)
          ..lineTo(-r * .5, 0)
          ..close(),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StarBurst oldDelegate) =>
      oldDelegate.progress != progress;
}
