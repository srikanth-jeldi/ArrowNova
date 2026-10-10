import 'dart:math';

import 'package:flutter/material.dart';

import '../core/progress_store.dart';
import '../ui.dart';
import '../game/puzzle.dart';
import 'garden_catalog.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({
    super.key,
    required this.progress,
    required this.onChanged,
  });
  final PlayerProgress progress;
  final VoidCallback onChanged;
  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  int slot = 0;
  void change(VoidCallback action) {
    setState(action);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final milestone = min(
      LevelCatalog.count,
      ((p.completed.length ~/ 50) + 1) * 50,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Your crystal garden')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${p.gardenPoints} garden points',
                style: const TextStyle(color: gold, fontSize: 27),
              ),
              Text(
                p.completed.length >= LevelCatalog.count
                    ? 'A complete journey. A garden of your own.'
                    : '${p.completed.length} levels cleared · Next milestone $milestone',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: LayoutBuilder(
                    builder: (context, box) => Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GardenPainter(p.placements),
                          ),
                        ),
                        for (var i = 0; i < 6; i++)
                          Positioned(
                            left: gardenSlots[i].dx * box.maxWidth - 22,
                            top: gardenSlots[i].dy * box.maxHeight + 14,
                            child: Semantics(
                              label: 'Garden spot ${i + 1}',
                              selected: i == slot,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: IconButton.filledTonal(
                                  onPressed: () => setState(() => slot = i),
                                  style: IconButton.styleFrom(
                                    backgroundColor: i == slot
                                        ? gold
                                        : navy.withValues(alpha: .8),
                                    foregroundColor: i == slot ? navy : ice,
                                  ),
                                  icon: Text('${i + 1}'),
                                  tooltip: 'Select spot ${i + 1}',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Decorate spot ${slot + 1}',
                      style: const TextStyle(fontSize: 23),
                    ),
                  ),
                  TextButton(
                    onPressed: p.placements.containsKey(slot)
                        ? () => change(() => p.placements.remove(slot))
                        : null,
                    child: const Text('Remove'),
                  ),
                ],
              ),
              const Text(
                'Choose a spot, then place an owned decoration. Moving or removing it is free.',
                style: TextStyle(color: muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              for (final item in gardenItems)
                Card(
                  color: const Color(0xFF15364E),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 58,
                          height: 70,
                          child: CustomPaint(
                            painter: DecorationPainter(item.id),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: gold,
                                ),
                              ),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.owned.contains(item.id)
                                    ? 'Owned'
                                    : p.completed.length < item.unlock
                                    ? 'Unlock at ${item.unlock} levels'
                                    : '${item.cost} points',
                                style: const TextStyle(
                                  fontFamily: 'ArrowNovaSans',
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: p.owned.contains(item.id)
                              ? () => change(() => p.place(item.id, slot))
                              : p.completed.length >= item.unlock &&
                                    p.gardenPoints >= item.cost
                              ? () => change(() {
                                  if (p.buy(item.id)) p.place(item.id, slot);
                                })
                              : null,
                          child: Text(
                            p.owned.contains(item.id) ? 'Place' : 'Buy',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Each new Classic win earns 10 points. Replays do not add points. Your garden is saved on this device.',
                  style: TextStyle(color: muted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const gardenSlots = [
  Offset(.28, .40),
  Offset(.5, .29),
  Offset(.72, .40),
  Offset(.27, .65),
  Offset(.5, .73),
  Offset(.73, .65),
];

class GardenPainter extends CustomPainter {
  GardenPainter(this.placements);
  final Map<int, String> placements;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF153C5C), Color(0xFF071B33)],
        ).createShader(Offset.zero & s),
    );
    final center = Offset(s.width / 2, s.height * .59);
    c.drawOval(
      Rect.fromCenter(
        center: center + const Offset(0, 18),
        width: s.width * .92,
        height: s.height * .56,
      ),
      Paint()..color = const Color(0xFF837349),
    );
    c.drawOval(
      Rect.fromCenter(
        center: center,
        width: s.width * .92,
        height: s.height * .56,
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF3EAD2), Color(0xFFADBFB2)],
        ).createShader(Offset.zero & s),
    );
    c.drawOval(
      Rect.fromCenter(
        center: center,
        width: s.width * .82,
        height: s.height * .47,
      ),
      Paint()..color = const Color(0xFF486F64),
    );
    c.drawOval(
      Rect.fromCenter(
        center: center,
        width: s.width * .67,
        height: s.height * .33,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = const Color(0xFFDFD7BB),
    );
    for (var i = 0; i < 24; i++) {
      final x = (i * 67 % 100) / 100 * s.width;
      final y = (i * 23 % 30) / 100 * s.height;
      c.drawCircle(
        Offset(x, y),
        i.isEven ? 1.3 : .7,
        Paint()..color = gold.withValues(alpha: .45),
      );
    }
    for (var i = 0; i < gardenSlots.length; i++) {
      final pos = Offset(
        gardenSlots[i].dx * s.width,
        gardenSlots[i].dy * s.height,
      );
      c.drawOval(
        Rect.fromCenter(
          center: pos + const Offset(0, 12),
          width: 56,
          height: 20,
        ),
        Paint()..color = const Color(0xFFD8CFB3),
      );
      if (placements[i] case final String id) {
        c.save();
        c.translate(pos.dx - 34, pos.dy - 65);
        DecorationPainter(id).paint(c, const Size(68, 80));
        c.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant GardenPainter oldDelegate) => true;
}

class DecorationPainter extends CustomPainter {
  DecorationPainter(this.id);
  final String id;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.scale(s.width / 70, s.height / 90);
    final base = Paint()..color = const Color(0xFFE8D8A7);
    c.drawOval(
      const Rect.fromLTWH(8, 72, 54, 14),
      Paint()
        ..color = const Color(0x50000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    c.drawOval(const Rect.fromLTWH(9, 67, 52, 14), base);
    final metal = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE2A0), Color(0xFFAA782B)],
      ).createShader(const Rect.fromLTWH(0, 0, 70, 90));
    if (id == 'lantern') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(21, 31, 28, 38),
          const Radius.circular(5),
        ),
        metal,
      );
      c.drawRect(
        const Rect.fromLTWH(25, 37, 20, 25),
        Paint()..color = const Color(0xFFFFEDA7),
      );
      c.drawCircle(
        const Offset(35, 49),
        16,
        Paint()
          ..color = const Color(0x80FFDD77)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      c.drawPath(
        Path()
          ..moveTo(17, 32)
          ..lineTo(35, 17)
          ..lineTo(53, 32)
          ..close(),
        metal,
      );
    } else if (id == 'fountain') {
      c.drawOval(const Rect.fromLTWH(10, 50, 50, 23), metal);
      c.drawOval(
        const Rect.fromLTWH(14, 50, 42, 15),
        Paint()..color = const Color(0xFF46BFDF),
      );
      c.drawRect(const Rect.fromLTWH(31, 30, 8, 30), base);
      c.drawOval(const Rect.fromLTWH(20, 25, 30, 12), metal);
      c.drawPath(
        Path()
          ..moveTo(15, 55)
          ..quadraticBezierTo(18, 12, 35, 28)
          ..quadraticBezierTo(52, 12, 55, 55),
        Paint()
          ..color = const Color(0xFF9DECFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else if (id == 'arch') {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(13, 13, 44, 65),
          const Radius.circular(22),
        ),
        metal,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(23, 25, 24, 60),
          const Radius.circular(15),
        ),
        Paint()..color = const Color(0xFF355F58),
      );
    } else if (id == 'obelisk') {
      c.drawPath(
        Path()
          ..moveTo(35, 9)
          ..lineTo(49, 29)
          ..lineTo(49, 70)
          ..lineTo(21, 70)
          ..lineTo(21, 29)
          ..close(),
        metal,
      );
      c.drawPath(
        Path()
          ..moveTo(35, 9)
          ..lineTo(35, 70)
          ..lineTo(21, 70)
          ..lineTo(21, 29)
          ..close(),
        Paint()..color = const Color(0xFFFFE9AA),
      );
    } else {
      c.drawLine(
        const Offset(35, 70),
        const Offset(35, 27),
        metal..strokeWidth = 5,
      );
      final count = id == 'tree' ? 9 : 6;
      for (var i = 0; i < count; i++) {
        final a = i * 2 * pi / count;
        final p = Offset(35 + cos(a) * 20, 35 + sin(a) * 19);
        c.drawLine(
          const Offset(35, 62),
          p,
          Paint()
            ..color = const Color(0xFF9BBBA5)
            ..strokeWidth = 2,
        );
        final diamond = Path()
          ..moveTo(p.dx, p.dy - 12)
          ..lineTo(p.dx + 9, p.dy)
          ..lineTo(p.dx, p.dy + 10)
          ..lineTo(p.dx - 9, p.dy)
          ..close();
        c.drawPath(
          diamond,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFBEF6FF), Color(0xFF227FDB)],
            ).createShader(diamond.getBounds()),
        );
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant DecorationPainter oldDelegate) =>
      id != oldDelegate.id;
}
