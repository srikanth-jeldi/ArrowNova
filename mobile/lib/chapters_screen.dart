import 'package:flutter/material.dart';

import 'core/progress_store.dart';
import 'core/chapter_gate.dart';
import 'game/chapters.dart';
import 'ui.dart';

class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({
    super.key,
    required this.progress,
    required this.save,
    required this.openLevel,
  });
  final PlayerProgress progress;
  final VoidCallback save;
  final Future<void> Function(int) openLevel;
  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  late int selected = ChapterCatalog.of(widget.progress.nextLevel)
      .clamp(1, ChapterCatalog.count);
  bool busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your worlds')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.progress.nextLevel >
            ChapterCatalog.last(ChapterCatalog.count)) ...[
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      await widget.openLevel(widget.progress.nextLevel);
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: Text('Continue Level ${widget.progress.nextLevel}'),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          '60 chapters · 6,000 puzzles',
          style: TextStyle(color: gold, fontSize: 24),
        ),
        const SizedBox(height: 8),
        const Text(
          '100 levels in each world. Finish a chapter, then watch one rewarded ad to unlock the next.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          initialValue: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Choose chapter',
            border: OutlineInputBorder(),
          ),
          items: [
            for (var c = 1; c <= ChapterCatalog.count; c++)
              DropdownMenuItem(
                value: c,
                child: Text(
                  '$c · ${ChapterCatalog.name(c)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: busy ? null : (value) => setState(() => selected = value!),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  const Color(0xff174d72),
                  const Color(0xff493461),
                  (selected % 6) / 5,
                )!,
                navy,
              ],
            ),
            border: Border.all(color: gold.withValues(alpha: .5)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(
                widget.progress.chapterOpen(selected)
                    ? Icons.landscape_rounded
                    : Icons.lock_outline,
                color: gold,
                size: 48,
              ),
              Text(
                ChapterCatalog.name(selected),
                textAlign: TextAlign.center,
                style: const TextStyle(color: gold, fontSize: 28),
              ),
              Text(
                'Levels ${ChapterCatalog.first(selected)}–${ChapterCatalog.last(selected)}',
                style: const TextStyle(color: ice),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.progress.completed.where((n) => ChapterCatalog.of(n) == selected).length} / 100 solved',
              ),
              if (!widget.progress.chapterOpen(selected)) ...[
                const SizedBox(height: 14),
                if (widget.progress.chapterEligible(selected))
                  FilledButton.icon(
                    icon: const Icon(Icons.ondemand_video),
                    label: const Text('Unlock chapter'),
                    onPressed: busy
                        ? null
                        : () async {
                            setState(() => busy = true);
                            await ensureChapter(
                              context,
                              widget.progress,
                              ChapterCatalog.first(selected),
                              widget.save,
                            );
                            if (mounted) setState(() => busy = false);
                          },
                  )
                else
                  Text(
                    'Finish Chapter ${selected - 1} to continue.',
                    textAlign: TextAlign.center,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (widget.progress.chapterOpen(selected))
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 100,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 85,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final n = ChapterCatalog.first(selected) + index;
              final done = widget.progress.completed.contains(n);
              return OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: done ? gold : ice,
                ),
                onPressed: !busy && widget.progress.unlocked(n)
                    ? () async {
                        setState(() => busy = true);
                        await widget.openLevel(n);
                        if (mounted) setState(() => busy = false);
                      }
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$n'),
                    if (done)
                      Text(
                        '★' * (widget.progress.bestStars[n] ?? 0),
                        style: const TextStyle(color: gold, fontSize: 11),
                      )
                    else if (widget.progress.skipped.contains(n))
                      const Text('Skipped', style: TextStyle(fontSize: 10))
                    else if (!widget.progress.unlocked(n))
                      const Icon(Icons.lock_outline, size: 14),
                  ],
                ),
              );
            },
          ),
      ],
    ),
  );
}
