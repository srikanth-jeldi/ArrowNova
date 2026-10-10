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
    required this.onNext,
    required this.onReplay,
    required this.onHome,
  });
  final int level, stars, moves;
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
                        'assets/art/victory-garden.png',
                        fit: BoxFit.cover,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xEFFFFFFF),
                              Color(0x00FFFFFF),
                              Color(0x00FFFFFF),
                              Color(0xFFF3F4EF),
                            ],
                            stops: [0, .29, .58, .85],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                        child: Column(
                          children: [
                            const Text(
                              'Beautifully solved!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: navy,
                                fontSize: 34,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'PUZZLES GROW BRIGHTER WORLDS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'ArrowNovaSans',
                                color: Color(0xFF51687C),
                                fontSize: 9,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 18),
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
                                    firstCompletion ? '+40' : '+0',
                                    'Coins',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                Expanded(
                                  child: _action(
                                    'Replay',
                                    Icons.replay,
                                    onReplay,
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                color: Color(0xFF51687C),
                                fontSize: 10,
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
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
  Widget _action(String text, IconData icon, VoidCallback action) =>
      FilledButton.icon(
        onPressed: action,
        icon: Icon(icon, size: 18),
        label: Text(text, style: const TextStyle(fontSize: 17)),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xF2FFFFFF),
          foregroundColor: navy,
          minimumSize: const Size(0, 44),
          side: const BorderSide(color: Color(0xFFD4DDE2)),
        ),
      );
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
