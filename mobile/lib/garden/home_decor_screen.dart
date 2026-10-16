import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/ads.dart';
import '../core/progress_store.dart';
import 'decor_collection.dart';

const _ink = Color(0xFF283C37);
const _accent = Color(0xFF346E5E);

class HomeDecorScreen extends StatefulWidget {
  const HomeDecorScreen({
    super.key,
    required this.progress,
    required this.onChanged,
    required this.onBack,
    this.showRewardAd,
  });
  final PlayerProgress progress;
  final VoidCallback onChanged, onBack;
  final Future<HintAdResult> Function()? showRewardAd;
  @override
  State<HomeDecorScreen> createState() => _HomeDecorScreenState();
}

class _HomeDecorScreenState extends State<HomeDecorScreen> {
  final scroll = ScrollController();
  final choicesKey = GlobalKey();

  void openChoices(int value) {
    setState(() => category = value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = choicesKey.currentContext;
      if (mounted && target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  Future<void> selectSlot(int value) async {
    if (busy || room.finished) return;
    final name = decorCategories[value];
    final id = room.placed[name];
    if (id == null) {
      openChoices(value);
      return;
    }
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(decorPiece(id)!.name),
        content: const Text(
          'Change this detail or remove it from the room. Unlocked items stay owned in this room.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'remove'),
            child: const Text('Remove'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'change'),
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (!mounted || busy || room.finished) return;
    if (action == 'remove') {
      save(() => room.remove(name));
    } else if (action == 'change') {
      openChoices(value);
    }
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void showRoom() {
    if (scroll.hasClients) {
      scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  int category = 0;
  bool ownedOnly = false, busy = false;
  HomeDecorProgress get progress => widget.progress.homeDecor;
  DecorRoom get room => progress.current;
  void save(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> watch(DecorPiece item) async {
    if (busy || room.finished || room.owns(item)) return;
    // Capture the room before awaiting: a late callback cannot credit another level.
    final target = room;
    setState(() => busy = true);
    var result = HintAdResult.unavailable;
    try {
      result = await (widget.showRewardAd ?? GameAds.instance.showHintAd)();
    } catch (_) {
      /* Availability never changes ownership. */
    }
    if (result == HintAdResult.earned && target.reward(item)) {
      widget.onChanged();
    }
    if (!mounted) return;
    setState(() => busy = false);
    message(
      result == HintAdResult.earned
          ? target.owns(item)
                ? '${item.name} unlocked for this room. Tap Place.'
                : '${target.adsFor(item)}/3 ads saved for ${item.name} in this room.'
          : result == HintAdResult.dismissed
          ? 'Ad not completed. Your progress is saved.'
          : 'No ad available. Try later or use an owned item.',
    );
  }

  Future<void> gallery() async {
    final finished = progress.rooms.entries
        .where((e) => e.value.finished)
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F6F0),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: finished.isEmpty ? 2 : finished.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Text(
                  'Your finished rooms',
                  style: TextStyle(color: _ink, fontSize: 24),
                );
              }
              if (finished.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'Finish your first room to start your collection.',
                    style: TextStyle(color: _ink),
                  ),
                );
              }
              final e = finished[index - 1];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Room ${e.key} · ${decorRoomNames[(e.key - 1) % 3]}',
                      style: const TextStyle(color: _ink),
                    ),
                  ),
                  DecorRoomScene(room: e.value, level: e.key),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = DecorPiece(category, 0);
    return PopScope(
      canPop: !busy,
      child: Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          fontFamily: 'ArrowNovaSans',
          colorScheme: ColorScheme.fromSeed(seedColor: _accent),
          scaffoldBackgroundColor: const Color(0xFFF8F6F0),
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F6F0),
            leading: IconButton(
              onPressed: busy ? null : widget.onBack,
              tooltip: 'Back to garden',
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('Home studio'),
            actions: [
              IconButton(
                onPressed: busy ? null : gallery,
                tooltip: 'Finished rooms',
                icon: const Icon(Icons.collections_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ROOM ${progress.level.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  color: _accent,
                                ),
                              ),
                              Text(
                                decorRoomNames[(progress.level - 1) % 3],
                                style: const TextStyle(
                                  fontSize: 25,
                                  color: _ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${room.placed.length}/7 styled',
                          style: const TextStyle(color: _accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      decorRoomBriefs[(progress.level - 1) % 3],
                      style: const TextStyle(color: _accent, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    DecorRoomScene(
                      room: room,
                      level: progress.level,
                      selected: room.finished ? null : selected.category,
                      onSelect: busy || room.finished ? null : selectSlot,
                    ),
                    const SizedBox(height: 12),
                    if (room.finished) ...[
                      const Text(
                        'Beautifully styled. Saved to your gallery.',
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FilledButton.icon(
                        key: const ValueKey('decor-next'),
                        onPressed: busy
                            ? null
                            : () => save(() {
                                progress.next();
                                category = 0;
                                ownedOnly = false;
                                showRoom();
                              }),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Start next room'),
                      ),
                      const Text(
                        'Next room starts with free starter items. Premium items need 3 ads again in each new room.',
                        style: TextStyle(color: _ink, fontSize: 12),
                      ),
                    ] else ...[
                      Text(
                        'Pick a detail. Make it yours.',
                        key: choicesKey,
                        style: TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < decorCategories.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(decorCategories[i]),
                                  selected: category == i,
                                  onSelected: busy
                                      ? null
                                      : (_) => setState(() => category = i),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All options'),
                            selected: !ownedOnly,
                            onSelected: busy
                                ? null
                                : (_) => setState(() => ownedOnly = false),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Owned'),
                            selected: ownedOnly,
                            onSelected: busy
                                ? null
                                : (_) => setState(() => ownedOnly = true),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '7 starter pieces are yours free. Premium: 3 optional ads per item, for this room only. Progress saves after each earned ad.',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                      for (final item in decorPieces.where(
                        (i) =>
                            i.categoryIndex == category &&
                            (!ownedOnly || room.owns(i)),
                      ))
                        card(item),
                      const SizedBox(height: 8),
                      FilledButton(
                        key: const ValueKey('decor-finish'),
                        onPressed: busy || !room.complete
                            ? null
                            : () => save(() {
                                progress.finish();
                                showRoom();
                              }),
                        child: Text(
                          room.complete
                              ? 'Finish & save room'
                              : 'Style all 7 details to finish',
                        ),
                      ),
                      const Text(
                        'You can finish every room with free items. Premium is optional.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _ink, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget card(DecorPiece item) {
    final owns = room.owns(item);
    final placed = room.placed[item.category] == item.id;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: placed ? _accent : const Color(0xFFE3E4DB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(width: 96, height: 96, child: DecorSprite(item: item)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    decorCollections[item.collection].toUpperCase(),
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    decorStyleHint(progress.level, item.collection),
                    style: const TextStyle(color: _accent, fontSize: 11),
                  ),
                  Text(
                    item.premium
                        ? owns
                              ? 'Owned · this room'
                              : 'Premium · ${room.adsFor(item)}/3 ads · this room only'
                        : 'Owned · free in every room',
                    style: const TextStyle(color: _ink, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  FilledButton.tonalIcon(
                    key: ValueKey('decor-action-${item.id}'),
                    onPressed: busy
                        ? null
                        : placed
                        ? () => save(() {
                            room.remove(item.category);
                            showRoom();
                          })
                        : owns
                        ? () => save(() {
                            room.place(item);
                            showRoom();
                          })
                        : () => watch(item),
                    icon: Icon(
                      placed
                          ? Icons.remove_circle_outline
                          : owns
                          ? Icons.add
                          : Icons.play_circle_outline,
                      size: 17,
                    ),
                    label: Text(
                      busy
                          ? 'Ad in progress…'
                          : placed
                          ? 'Remove'
                          : owns
                          ? 'Place'
                          : 'Watch ad (${room.adsFor(item)}/3)',
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () {
                            final preview = DecorRoom(
                              placed: Map.of(room.placed),
                            );
                            preview.placed[item.category] = item.id;
                            showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('${item.name} · preview'),
                                content: SizedBox(
                                  width: 360,
                                  child: DecorRoomScene(
                                    room: preview,
                                    level: progress.level,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Back to choices'),
                                  ),
                                ],
                              ),
                            );
                          },
                    child: const Text('Preview in room'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Category-specific sockets keep perspective, scale and occlusion consistent.
// Layer order: wall treatments, rug, lights, sofa, pillows, vase.
const _sockets = <int, Rect>{
  3: Rect.fromLTWH(.55, .06, .42, .58),
  5: Rect.fromLTWH(.10, .18, .33, .25),
  2: Rect.fromLTWH(.10, .66, .78, .32),
  6: Rect.fromLTWH(.76, .40, .22, .43),
  0: Rect.fromLTWH(.03, .45, .75, .39),
  // Rest the cushion against the left backrest, above the seat front edge.
  1: Rect.fromLTWH(.17, .495, .145, .128),
  4: Rect.fromLTWH(.74, .72, .22, .25),
};

class DecorRoomScene extends StatelessWidget {
  const DecorRoomScene({
    super.key,
    required this.room,
    this.level = 1,
    this.selected,
    this.onSelect,
  });
  final DecorRoom room;
  final int level;
  final String? selected;
  final ValueChanged<int>? onSelect;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          key: const ValueKey('decor-room-scene'),
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/art/decor/room${(level - 1) % 3 == 0 ? '' : '_${(level - 1) % 3}'}.webp',
                fit: BoxFit.cover,
                cacheWidth: 1024,
              ),
            ),
            for (final e in _sockets.entries)
              Positioned(
                left: e.value.left * box.maxWidth,
                top: e.value.top * box.maxHeight,
                width: e.value.width * box.maxWidth,
                height: e.value.height * box.maxHeight,
                child: Builder(
                  builder: (_) {
                    final id = room.placed[decorCategories[e.key]];
                    return GestureDetector(
                      onTap: onSelect == null ? null : () => onSelect!(e.key),
                      behavior: HitTestBehavior.opaque,
                      child: Semantics(
                        label: decorCategories[e.key],
                        button: onSelect != null,
                        child: id != null
                            ? DecorSprite(
                                item: decorPiece(id)!,
                                fit: e.key == 3 ? BoxFit.fill : BoxFit.contain,
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
              ),
            if (onSelect != null)
              for (final e in _sockets.entries)
                if (!room.placed.containsKey(decorCategories[e.key]))
                  Positioned(
                    left: e.value.center.dx * box.maxWidth - 24,
                    top: e.value.center.dy * box.maxHeight - 24,
                    width: 48,
                    height: 48,
                    child: IconButton.filledTonal(
                      key: ValueKey('decor-add-${e.key}'),
                      tooltip: 'Add ${decorCategories[e.key]}',
                      onPressed: () => onSelect!(e.key),
                      icon: const Icon(Icons.add),
                    ),
                  ),
          ],
        ),
      ),
    ),
  );
}

class DecorSprite extends StatefulWidget {
  const DecorSprite({super.key, required this.item, this.fit = BoxFit.contain});
  final DecorPiece item;
  final BoxFit fit;
  @override
  State<DecorSprite> createState() => _DecorSpriteState();
}

class _DecorSpriteState extends State<DecorSprite> {
  ImageStream? stream;
  ImageInfo? info;
  late final listener = ImageStreamListener((value, _) {
    if (!mounted) {
      value.dispose();
      return;
    }
    setState(() {
      info?.dispose();
      info = value;
    });
  });
  void resolve() {
    stream?.removeListener(listener);
    stream = AssetImage(widget.item.atlas)
        .resolve(createLocalImageConfiguration(context));
    stream!.addListener(listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    resolve();
  }

  @override
  void didUpdateWidget(covariant DecorSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.atlas != widget.item.atlas) resolve();
  }

  @override
  void dispose() {
    stream?.removeListener(listener);
    info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => info == null
      ? const SizedBox.shrink()
      : CustomPaint(
          painter: _SpritePainter(
            info!.image,
            widget.item.categoryIndex,
            widget.item.collection,
            widget.fit,
          ),
        );
}

class _SpritePainter extends CustomPainter {
  const _SpritePainter(this.image, this.cell, this.collection, this.fit);
  final ui.Image image;
  final int cell, collection;
  final BoxFit fit;
  // Individual sprite bounds in the original 1024 x 1536 atlases. Cropping
  // by the actual artwork bounds avoids clipping wider sofas at grid edges.
  static const bounds = [
    [
      Rect.fromLTRB(15, 85, 563, 335),
      Rect.fromLTRB(614, 42, 942, 343),
      Rect.fromLTRB(10, 468, 561, 687),
      Rect.fromLTRB(574, 389, 985, 747),
      Rect.fromLTRB(129, 737, 431, 1092),
      Rect.fromLTRB(566, 798, 962, 1090),
      Rect.fromLTRB(190, 1098, 366, 1510),
    ],
    [
      Rect.fromLTRB(10, 85, 573, 314),
      Rect.fromLTRB(625, 42, 944, 324),
      Rect.fromLTRB(0, 447, 578, 683),
      Rect.fromLTRB(584, 345, 1015, 725),
      Rect.fromLTRB(100, 682, 443, 1090),
      Rect.fromLTRB(560, 737, 1000, 1079),
      Rect.fromLTRB(107, 1085, 474, 1520),
    ],
    [
      Rect.fromLTRB(20, 77, 625, 311),
      Rect.fromLTRB(663, 41, 962, 326),
      Rect.fromLTRB(10, 454, 607, 688),
      Rect.fromLTRB(612, 356, 990, 741),
      Rect.fromLTRB(90, 730, 420, 1092),
      Rect.fromLTRB(568, 775, 973, 1088),
      Rect.fromLTRB(174, 1097, 361, 1520),
    ],
    [
      Rect.fromLTRB(18, 73, 574, 318),
      Rect.fromLTRB(639, 40, 940, 326),
      Rect.fromLTRB(10, 449, 588, 659),
      Rect.fromLTRB(613, 337, 964, 715),
      Rect.fromLTRB(133, 690, 428, 1086),
      Rect.fromLTRB(562, 770, 995, 1063),
      Rect.fromLTRB(190, 1089, 362, 1520),
    ],
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final b = bounds[collection][cell];
    final src = Rect.fromLTRB(
      b.left * image.width / 1024,
      b.top * image.height / 1536,
      b.right * image.width / 1024,
      b.bottom * image.height / 1536,
    );
    final fitted = applyBoxFit(fit, src.size, size);
    canvas.drawImageRect(
      image,
      src,
      Alignment.center.inscribe(fitted.destination, Offset.zero & size),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _SpritePainter old) =>
      old.image != image ||
      old.cell != cell ||
      old.collection != collection ||
      old.fit != fit;
}
