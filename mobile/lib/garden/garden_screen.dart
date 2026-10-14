import 'package:flutter/material.dart';

import '../core/ads.dart';
import '../core/progress_store.dart';
import '../ui.dart';
import 'garden_catalog.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({
    super.key,
    required this.progress,
    required this.onChanged,
    this.showRewardAd,
  });
  final PlayerProgress progress;
  final VoidCallback onChanged;
  final Future<HintAdResult> Function()? showRewardAd;
  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void placeItem(GardenItem item, {bool buy = false}) {
    change(() {
      if (!buy || widget.progress.buy(item.id)) {
        widget.progress.place(item.id, slot);
      }
    });
    if (scroll.hasClients) {
      scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  int slot = 0;
  bool editing = false;
  bool adBusy = false;
  String category = 'All';
  void change(VoidCallback action) {
    setState(action);
    widget.onChanged();
  }

  Future<void> watchFor(GardenItem item) async {
    if (adBusy || !item.premium || widget.progress.owned.contains(item.id)) {
      return;
    }
    setState(() => adBusy = true);
    var result = HintAdResult.unavailable;
    try {
      result = await (widget.showRewardAd ?? GameAds.instance.showHintAd)();
    } catch (_) {
      /* An unavailable ad never changes the balance. */
    }
    final p = widget.progress;
    if (result == HintAdResult.earned && p.recordGardenReward(item.id)) {
      // Save even if the route was externally removed during the ad.
      widget.onChanged();
    }
    if (!mounted) return;
    setState(() => adBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == HintAdResult.earned
              ? p.owned.contains(item.id)
                    ? '${item.name} unlocked! Place it in your garden.'
                    : '${p.gardenCredits(item.id)}/$gardenPremiumAds saved for ${item.name}.'
              : result == HintAdResult.dismissed
              ? 'Ad not completed. Your saved progress is unchanged.'
              : 'No ad available right now. Try again later; your progress is saved.',
        ),
      ),
    );
  }

  bool visible(GardenItem item) => switch (category) {
    'All' => true,
    'Owned' => widget.progress.owned.contains(item.id),
    'Premium' => item.premium,
    _ => item.category == category,
  };

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    return PopScope(
      canPop: !adBusy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Your garden')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${p.gardenPoints} garden points',
                  style: const TextStyle(color: gold, fontSize: 27),
                ),
                Text(
                  '${p.owned.length}/${gardenItems.length} decorations collected · ${p.placements.length}/$gardenSlotCount placed',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 14),
                GardenScene(
                  progress: p,
                  editing: editing && !adBusy,
                  selected: slot,
                  onSelect: (value) => setState(() => slot = value),
                  onMove: (index, x, y) =>
                      setState(() => p.moveGarden(index, x, y)),
                  onMoveEnd: widget.onChanged,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: adBusy
                      ? null
                      : () => setState(() => editing = !editing),
                  icon: Icon(
                    editing ? Icons.check_rounded : Icons.edit_outlined,
                  ),
                  label: Text(editing ? 'Done decorating' : 'Decorate garden'),
                ),
                if (!editing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Create your own garden retreat with flowers, jars and furniture. Collect pieces, then arrange them your way.',
                      style: TextStyle(color: muted, height: 1.5),
                    ),
                  ),
                if (editing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Decorate spot ${slot + 1}',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      TextButton(
                        onPressed: !adBusy && p.placements.containsKey(slot)
                            ? () => change(() => p.placements.remove(slot))
                            : null,
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                  const Text(
                    'Choose a spot and place an item. Drag placed items to move them. Moving and removing are free.',
                    style: TextStyle(color: muted, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final c in [
                          'All',
                          'Owned',
                          'Flowers',
                          'Pots & jars',
                          'Furniture',
                          'Landmarks',
                          'Premium',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(c),
                              selected: category == c,
                              onSelected: adBusy
                                  ? null
                                  : (_) => setState(() => category = c),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final item in gardenItems.where(visible)) itemCard(item),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'New puzzle wins earn garden points. Replays do not add points. Premium pieces unlock after 3 completed rewarded ads each, at your own pace. Your collection and ad progress are saved on this device.',
                    style: TextStyle(color: muted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget itemCard(GardenItem item) {
    final p = widget.progress;
    final owned = p.owned.contains(item.id);
    final credits = p.gardenCredits(item.id);
    final canBuy =
        p.completed.length >= item.unlock && p.gardenPoints >= item.cost;
    return Card(
      key: ValueKey('garden-card-${item.id}'),
      color: const Color(0xFF15364E),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 82,
                  height: 86,
                  child: GardenDecoration(item.id),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontSize: 20, color: gold),
                      ),
                      Text(
                        item.description,
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        owned
                            ? 'Owned · place anytime'
                            : item.premium
                            ? 'Premium · $credits/$gardenPremiumAds ads completed'
                            : p.completed.length < item.unlock
                            ? 'Unlock at ${item.unlock} Classic wins · ${item.cost} points'
                            : '${item.cost} garden points',
                        style: const TextStyle(fontSize: 12, color: ice),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.premium && !owned) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: credits / gardenPremiumAds,
                color: gold,
                backgroundColor: navy,
              ),
              const SizedBox(height: 8),
              const Text(
                'Each completed ad adds 1 credit to this item. All 3 unlock it permanently on this device.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: ValueKey('garden-action-${item.id}'),
                onPressed: adBusy
                    ? null
                    : owned
                    ? () => placeItem(item)
                    : item.premium
                    ? () => watchFor(item)
                    : canBuy
                    ? () => placeItem(item, buy: true)
                    : null,
                icon: Icon(
                  owned
                      ? Icons.add_location_alt_outlined
                      : item.premium
                      ? Icons.ondemand_video
                      : Icons.add,
                ),
                label: Text(
                  owned
                      ? 'Place'
                      : item.premium
                      ? adBusy
                            ? 'Ad in progress…'
                            : 'Watch ad · +1 credit'
                      : 'Buy & place',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// First six baselines are unchanged, preserving existing gardens.
const gardenSlots = [
  Offset(.23, .39),
  Offset(.53, .38),
  Offset(.75, .43),
  Offset(.20, .64),
  Offset(.69, .63),
  Offset(.72, .80),
  Offset(.38, .55),
  Offset(.48, .73),
  Offset(.34, .88),
  Offset(.82, .58),
  Offset(.17, .86),
  Offset(.55, .91),
];

class GardenScene extends StatelessWidget {
  const GardenScene({
    super.key,
    required this.progress,
    required this.editing,
    required this.selected,
    required this.onSelect,
    required this.onMove,
    required this.onMoveEnd,
  });
  final PlayerProgress progress;
  final bool editing;
  final int selected;
  final ValueChanged<int> onSelect;
  final void Function(int, double, double) onMove;
  final VoidCallback onMoveEnd;
  Offset position(int i) {
    final saved = progress.gardenPositions[i];
    return saved == null ? gardenSlots[i] : Offset(saved.x, saved.y);
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: LayoutBuilder(
        builder: (context, box) {
          final ordered = progress.placements.keys.toList()
            ..sort((a, b) => position(a).dy.compareTo(position(b).dy));
          return Stack(
            key: const ValueKey('garden-scene'),
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/art/garden-courtyard.webp',
                  fit: BoxFit.cover,
                  cacheWidth: 1000,
                ),
              ),
              for (final i in ordered)
                (() {
                  final item = gardenItems.firstWhere(
                    (item) => item.id == progress.placements[i],
                  );
                  final point = position(i);
                  final width = box.maxWidth * item.scale;
                  return Positioned(
                    key: ValueKey('garden-slot-$i'),
                    left: point.dx * box.maxWidth - width / 2,
                    top: point.dy * box.maxHeight - width * .9,
                    width: width,
                    height: width,
                    child: GestureDetector(
                      key: ValueKey('garden-item-${item.id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: editing ? () => onSelect(i) : null,
                      onPanStart: editing ? (_) => onSelect(i) : null,
                      onPanUpdate: editing
                          ? (details) {
                              final current = position(i);
                              onMove(
                                i,
                                current.dx + details.delta.dx / box.maxWidth,
                                current.dy + details.delta.dy / box.maxHeight,
                              );
                            }
                          : null,
                      onPanEnd: editing ? (_) => onMoveEnd() : null,
                      onPanCancel: editing ? onMoveEnd : null,
                      child: Semantics(
                        label: '${item.name}, spot ${i + 1}',
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: editing && selected == i
                                ? Border.all(color: gold, width: 2)
                                : null,
                          ),
                          child: GardenDecoration(item.id),
                        ),
                      ),
                    ),
                  );
                })(),
              if (editing)
                for (var i = 0; i < gardenSlotCount; i++)
                  Positioned(
                    left: position(i).dx * box.maxWidth - 17,
                    top: position(i).dy * box.maxHeight - 10,
                    width: 34,
                    height: 34,
                    child: IconButton.filledTonal(
                      padding: EdgeInsets.zero,
                      tooltip: 'Select spot ${i + 1}',
                      onPressed: () => onSelect(i),
                      style: IconButton.styleFrom(
                        backgroundColor: i == selected
                            ? gold
                            : navy.withValues(alpha: .85),
                        foregroundColor: i == selected ? navy : ice,
                      ),
                      icon: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 12),
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

class GardenDecoration extends StatelessWidget {
  const GardenDecoration(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    final index = gardenItems.indexWhere((item) => item.id == id);
    if (index < 0) return const SizedBox.shrink();
    final asset = gardenItems[index].asset;
    if (asset != null) {
      return Image.asset(asset, fit: BoxFit.contain, cacheWidth: 320);
    }
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
