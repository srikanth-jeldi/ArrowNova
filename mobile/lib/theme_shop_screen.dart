import 'package:flutter/material.dart';

import 'core/progress_store.dart';
import 'game/board.dart';
import 'game/board_themes.dart';
import 'game/puzzle.dart';
import 'ui.dart';

class ThemeShopScreen extends StatefulWidget {
  const ThemeShopScreen({
    super.key,
    required this.progress,
    required this.onChanged,
  });
  final PlayerProgress progress;
  final VoidCallback onChanged;
  @override
  State<ThemeShopScreen> createState() => _ThemeShopScreenState();
}

class _ThemeShopScreenState extends State<ThemeShopScreen> {
  Future<void> select(BoardTheme theme) async {
    final progress = widget.progress;
    if (!progress.themes.contains(theme.id)) {
      if (progress.coins < theme.cost) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Unlock ${theme.name}?'),
          content: Text(
            'Spend ${theme.cost} earned coins. This theme stays yours on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Unlock'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true || !progress.buyTheme(theme.id)) return;
    }
    setState(() => progress.selectedTheme = theme.id);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: navy,
    appBar: AppBar(title: const Text('Crystal rewards')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${widget.progress.coins} coins available',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: gold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Earn coins from puzzle wins and daily streaks. Choose a matching arrow colour and board theme. No cash purchase required.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 12),
        const Text(
          'Daily challenge streak bonus: 20 · 30 · 40 · 50 · 60 · 80 · 100 coins. The cycle repeats every 7 days; a missed day starts a new streak.',
          style: TextStyle(color: ice),
        ),
        for (final theme in boardThemes)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      theme.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 140,
                      color: theme.background,
                      child: IgnorePointer(
                        child: ArrowBoard(
                          theme: theme,
                          game: GameSession(TrainingCatalog.get(1)),
                          onTap: (_) {},
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed:
                          widget.progress.selectedTheme == theme.id ||
                              (!widget.progress.themes.contains(theme.id) &&
                                  widget.progress.coins < theme.cost)
                          ? null
                          : () => select(theme),
                      child: Text(
                        widget.progress.selectedTheme == theme.id
                            ? 'Selected'
                            : widget.progress.themes.contains(theme.id)
                            ? 'Use theme'
                            : widget.progress.coins < theme.cost
                            ? '${theme.cost - widget.progress.coins} more coins needed'
                            : 'Unlock · ${theme.cost} coins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
