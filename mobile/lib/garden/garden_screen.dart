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
  bool editing = false;
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
    final remainingItems = gardenItems
        .where((item) => !p.owned.contains(item.id))
        .toList();
    final nextItem = remainingItems.isEmpty ? null : remainingItems.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Your garden')),
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
                    ? '${p.completed.length} levels cleared · Your journey keeps growing'
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
                          child: Image.asset(
                            'assets/art/garden-courtyard.webp',
                            fit: BoxFit.cover,
                            cacheWidth: 1000,
                          ),
                        ),
                        for (var i = 0; i < 6; i++)
                          if (p.placements[i] != null)
                            Positioned(
                              left:
                                  gardenSlots[i].dx * box.maxWidth -
                                  box.maxWidth * .10,
                              top:
                                  gardenSlots[i].dy * box.maxHeight -
                                  box.maxWidth * .18,
                              width: box.maxWidth * .20,
                              height: box.maxWidth * .20,
                              child: IgnorePointer(
                                child: GardenDecoration(p.placements[i]!),
                              ),
                            ),
                        if (editing)
                          for (var i = 0; i < 6; i++)
                            Positioned(
                              left: gardenSlots[i].dx * box.maxWidth - 22,
                              top: gardenSlots[i].dy * box.maxHeight - 4,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: IconButton.filledTonal(
                                  tooltip: 'Select spot ${i + 1}',
                                  onPressed: () => setState(() => slot = i),
                                  style: IconButton.styleFrom(
                                    backgroundColor: i == slot
                                        ? gold
                                        : navy.withValues(alpha: .8),
                                    foregroundColor: i == slot ? navy : ice,
                                  ),
                                  icon: Text((i + 1).toString()),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (nextItem != null) ...[
                Card(
                  color: const Color(0xFF15364E),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next decoration: ${nextItem.name}',
                          style: const TextStyle(
                            color: gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: nextItem.unlock == 0
                              ? 1
                              : (p.completed.length / nextItem.unlock).clamp(
                                  0.0,
                                  1.0,
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.completed.length < nextItem.unlock
                              ? '${nextItem.unlock - p.completed.length} more Classic levels to unlock · ${nextItem.cost} garden points'
                              : p.gardenPoints < nextItem.cost
                              ? 'Unlocked · ${nextItem.cost - p.gardenPoints} more garden points needed'
                              : 'Ready to add · ${nextItem.cost} garden points',
                          style: const TextStyle(color: ice),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => setState(() => editing = !editing),
                icon: Icon(editing ? Icons.check_rounded : Icons.edit_outlined),
                label: Text(editing ? 'Done decorating' : 'Decorate garden'),
              ),
              if (editing) ...[
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
                            child: GardenDecoration(item.id),
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
                                    fontSize: 12,
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
              ],
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

// Baselines on the lawn, ordered from back to front.
const gardenSlots = [
  Offset(.23, .39),
  Offset(.53, .38),
  Offset(.75, .43),
  Offset(.20, .64),
  Offset(.69, .63),
  Offset(.72, .80),
];

class GardenDecoration extends StatelessWidget {
  const GardenDecoration(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    final index = gardenItems.indexWhere((item) => item.id == id);
    if (index < 0) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) => ClipRect(
          child: OverflowBox(
            alignment: Alignment((index % 3) - 1.0, index < 3 ? -1 : 1),
            maxWidth: box.maxWidth * 3,
            minWidth: box.maxWidth * 3,
            maxHeight: box.maxHeight * 2,
            minHeight: box.maxHeight * 2,
            child: Image.asset(
              'assets/art/garden-decorations.webp',
              fit: BoxFit.fill,
              cacheWidth: 1536,
            ),
          ),
        ),
      ),
    );
  }
}
