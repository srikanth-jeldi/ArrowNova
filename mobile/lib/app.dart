import 'package:flutter/material.dart';

import 'core/progress_store.dart';
import 'game_screen.dart';
import 'game/puzzle.dart';
import 'ui.dart';
import 'garden/garden_screen.dart';
import 'duel/duel_screen.dart';

class ArrowNovaApp extends StatelessWidget {
  const ArrowNovaApp({super.key, this.initialProgress});
  final PlayerProgress? initialProgress;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ArrowNova',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF35CEFF),
        brightness: Brightness.dark,
        surface: navy,
      ),
      fontFamily: 'ArrowNovaSerif',
    ),
    home: HomeScreen(initialProgress: initialProgress),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialProgress});
  final PlayerProgress? initialProgress;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final store = ProgressStore();
  PlayerProgress progress = PlayerProgress();
  bool loading = true;
  String? storageWarning;
  Future<void> _saveQueue = Future.value();
  @override
  void initState() {
    super.initState();
    if (widget.initialProgress != null) {
      progress = widget.initialProgress!;
      loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      progress = await store.read();
    } catch (_) {
      storageWarning =
          'Device storage is unavailable. Progress lasts for this session.';
    }
    if (mounted) setState(() => loading = false);
  }

  void save() {
    if (widget.initialProgress != null) return;
    final snapshot = PlayerProgress.fromJson(progress.toJson());
    _saveQueue = _saveQueue.then((_) async {
      try {
        await store.save(snapshot);
      } catch (_) {
        if (mounted) {
          setState(
            () => storageWarning =
                'Progress could not be saved. Keep the app open and try again.',
          );
        }
      }
    });
  }

  Future<void> openLevel(int level) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          level: level,
          progress: progress,
          onComplete: (completed, stars) {
            progress.completed.add(completed);
            if (stars > (progress.bestStars[completed] ?? 0)) {
              progress.bestStars[completed] = stars;
            }
            save();
          },
          onSettingsChanged: save,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> openGarden() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GardenScreen(progress: progress, onChanged: save),
      ),
    );
    if (mounted) setState(() {});
  }

  void openDuel() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => DuelScreen(progress: progress)),
  );

  void levels() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: navy,
    builder: (sheet) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheet).height * .78,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Your journey', style: TextStyle(fontSize: 26)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheet),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                '${progress.completed.length} / ${LevelCatalog.count} levels complete',
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 90,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: LevelCatalog.count,
                  itemBuilder: (context, index) {
                    final n = index + 1;
                    final unlocked = progress.unlocked(n);
                    final done = progress.completed.contains(n);
                    return Semantics(
                      label: 'Level $n${done ? ', completed' : ''}',
                      child: OutlinedButton(
                        onPressed: unlocked
                            ? () {
                                Navigator.pop(sheet);
                                openLevel(n);
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: done ? gold : ice,
                          backgroundColor: done
                              ? const Color(0xFF214563)
                              : const Color(0xFF102C46),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            unlocked
                                ? Text(
                                    '$n',
                                    style: const TextStyle(fontSize: 23),
                                  )
                                : const Icon(Icons.lock_outline, size: 22),
                            if (done)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  3,
                                  (i) => Icon(
                                    i < (progress.bestStars[n] ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: gold,
                                    size: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void settings() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: navy,
    builder: (sheet) => StatefulBuilder(
      builder: (context, update) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Make it yours', style: TextStyle(fontSize: 27)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Crystal sounds'),
                value: progress.sound,
                onChanged: (value) {
                  update(() => progress.sound = value);
                  save();
                },
              ),
              SwitchListTile(
                title: const Text('Haptic feedback'),
                value: progress.haptics,
                onChanged: (value) {
                  update(() => progress.haptics = value);
                  save();
                },
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Play without an account. Progress is saved on this device. Clearing app or browser data removes it.',
                  style: TextStyle(color: muted, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
              const Text(
                'ArrowNova • EpitomeHub Technologies',
                style: TextStyle(color: gold, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Atmosphere(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 510),
            child: loading
                ? const CircularProgressIndicator()
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 20,
                    ),
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF193B54),
                              border: Border.all(
                                color: const Color(0xFF476478),
                              ),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: gold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WELCOME, EXPLORER',
                                  style: TextStyle(
                                    fontFamily: 'ArrowNovaSans',
                                    letterSpacing: 2,
                                    fontSize: 9,
                                    color: muted,
                                  ),
                                ),
                                Text(
                                  'Your quiet adventure',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Settings',
                            onPressed: settings,
                            icon: const Icon(Icons.tune_rounded, color: gold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Center(
                        child: Text(
                          'A LITTLE FOCUS. A BRIGHTER MIND.',
                          style: TextStyle(
                            fontFamily: 'ArrowNovaSans',
                            fontSize: 9,
                            letterSpacing: 2.7,
                            color: muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: SizedBox(
                          width: 205,
                          height: 205,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(42),
                            child: Image.asset(
                              'assets/branding/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ArrowNova',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 49, letterSpacing: -2),
                      ),
                      const Text(
                        'T H I N K .   M O V E .   S O L V E .',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'ArrowNovaSans',
                          color: gold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 30),
                      GoldButton(
                        label: progress.completed.isEmpty
                            ? 'Play now'
                            : 'Continue journey',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => openLevel(progress.nextLevel),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'CLASSIC  /  LEVEL ${progress.nextLevel.toString().padLeft(2, '0')}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'ArrowNovaSans',
                          fontSize: 10,
                          letterSpacing: 2,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: homeTile(
                              Icons.route_rounded,
                              'Your journey',
                              '${progress.completed.length} / ${LevelCatalog.count} cleared',
                              levels,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: homeTile(
                              Icons.auto_awesome,
                              'Crystal rewards',
                              '${progress.coins} coins earned',
                              () {
                                showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: navy,
                                    title: const Text('Your crystal rewards'),
                                    content: Text(
                                      '${progress.coins} coins\n${progress.gardenPoints} garden points\n\n'
                                      'First-time level wins earn 40 coins and 10 garden points. Visit your garden to place decorations. New items unlock at journey milestones.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Got it'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: homeTile(
                              Icons.bolt,
                              'Live Duel',
                              '60-second rivalry',
                              openDuel,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: homeTile(
                              Icons.park_outlined,
                              'Your garden',
                              '${progress.gardenPoints} points to grow',
                              openGarden,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite,
                            color: Color(0xFFFF657A),
                            size: 15,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Three hearts. One clear path.',
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                        ],
                      ),
                      if (storageWarning != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            storageWarning!,
                            style: const TextStyle(color: gold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 32),
                      const Text(
                        'POWERED BY EPITOMEHUB TECHNOLOGIES',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'ArrowNovaSans',
                          fontSize: 8,
                          letterSpacing: 1.5,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );

  Widget homeTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => Material(
    color: const Color(0xFF102C46),
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 21),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF345573)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: gold, size: 29),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: muted)),
          ],
        ),
      ),
    ),
  );
}
