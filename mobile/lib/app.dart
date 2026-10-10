import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';

import 'package:url_launcher/url_launcher.dart';

import 'core/reminders.dart';
import 'game/daily.dart';
import 'core/ads.dart';
import 'core/music_service.dart';
import 'daily_chest_screen.dart';
import 'chapters_screen.dart';
import 'core/chapter_gate.dart';

import 'package:flutter/material.dart';

import 'core/progress_store.dart';
import 'game_screen.dart';
import 'game/puzzle.dart';
import 'ui.dart';
import 'garden/garden_screen.dart';

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
      fontFamily: 'ArrowNovaSans',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontWeight: FontWeight.w700),
        displaySmall: TextStyle(fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontWeight: FontWeight.w500),
        bodySmall: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final store = ProgressStore();
  late final Future<PackageInfo> packageInfo = PackageInfo.fromPlatform();
  PlayerProgress progress = PlayerProgress();
  bool loading = true;
  bool openingLevel = false;
  String? storageWarning;
  Future<void> _saveQueue = Future.value();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    MusicService.instance.setEnabled(progress.music);
    progress.dailyReminders = false;
    unawaited(
      DailyReminders.instance.sync(false, progress.dailyStars.keys.toSet()),
    );
    save();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      if (widget.initialProgress == null && progress.dailyReminders) {
        unawaited(
          DailyReminders.instance.sync(true, progress.dailyStars.keys.toSet()),
        );
      }
    }
  }

  Future<void> openDaily() async {
    if (openingLevel) return;
    openingLevel = true;
    final today = DateTime.now();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          level: 1,
          dailyDate: today,
          progress: progress,
          onComplete: (_, stars) {
            progress.completeDaily(today, stars);
            save();
            if (widget.initialProgress == null && progress.dailyReminders) {
              unawaited(
                DailyReminders.instance.sync(
                  true,
                  progress.dailyStars.keys.toSet(),
                ),
              );
            }
          },
          onSettingsChanged: save,
        ),
      ),
    );
    openingLevel = false;
    if (mounted) setState(() {});
  }

  Future<void> openHelp(String page) async {
    final uri = Uri.parse('https://www.epitomehub.com/arrownova-$page');
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      /* Show a readable fallback below. */
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(uri.toString())));
    }
  }

  void save() {
    if (widget.initialProgress != null) return;
    MusicService.instance.setEnabled(progress.music);
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

  Future<void> openLevel(int level, {bool training = false}) async {
    if (openingLevel) return;
    openingLevel = true;
    if (!training && !await ensureChapter(context, progress, level, save)) {
      openingLevel = false;
      return;
    }
    if (!mounted) {
      openingLevel = false;
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          level: level,
          startTraining:
              training ||
              (!progress.trainingCompleted && progress.completed.isEmpty),
          progress: progress,
          onComplete: (completed, stars) {
            if (progress.completed.add(completed)) {
              progress.recordAdCompletion();
            }
            if (stars > (progress.bestStars[completed] ?? 0)) {
              progress.bestStars[completed] = stars;
            }
            save();
          },
          onSettingsChanged: save,
        ),
      ),
    );
    openingLevel = false;
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

  Future<void> openChest() async {
    if (openingLevel) return;
    openingLevel = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DailyChestScreen(progress: progress, onChanged: save),
      ),
    );
    openingLevel = false;
    if (mounted) setState(() {});
  }

  Future<void> levels() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChaptersScreen(
          progress: progress,
          save: save,
          openLevel: openLevel,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void settings() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: navy,
    builder: (sheet) => StatefulBuilder(
      builder: (context, update) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: GameAds.instance.privacyRequired,
                  builder: (_, required, _) => required
                      ? TextButton(
                          onPressed: () {
                            Navigator.pop(sheet);
                            GameAds.instance.privacyOptions();
                          },
                          child: const Text('Ad privacy choices'),
                        )
                      : const SizedBox.shrink(),
                ),
                const Text('Make it yours', style: TextStyle(fontSize: 27)),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => openHelp('privacy'),
                      child: const Text('Privacy policy'),
                    ),
                    TextButton(
                      onPressed: () => openHelp('support'),
                      child: const Text('Help & support'),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Practice how to play'),
                  onPressed: () {
                    Navigator.pop(sheet);
                    openLevel(progress.nextLevel, training: true);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Game sounds'),
                  value: progress.sound,
                  onChanged: (value) {
                    update(() => progress.sound = value);
                    save();
                  },
                ),
                SwitchListTile(
                  title: const Text('Background music'),
                  subtitle: const Text('Quiet ambient loop'),
                  value: progress.music,
                  onChanged: (value) {
                    update(() => progress.music = value);
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
                FutureBuilder<PackageInfo>(
                  future: packageInfo,
                  builder: (context, snapshot) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      snapshot.hasData
                          ? 'Version ${snapshot.data!.version} · Build ${snapshot.data!.buildNumber}'
                          : snapshot.hasError
                          ? 'Version unavailable'
                          : 'Loading version…',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WELCOME, EXPLORER',
                                  style: TextStyle(
                                    fontFamily: 'ArrowNovaSans',
                                    letterSpacing: 2,
                                    fontSize: 12,
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
                            fontSize: 12,
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
                          fontSize: 12,
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
                          fontSize: 12,
                          letterSpacing: 2,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: homeTile(
                                Icons.route_rounded,
                                'Your journey',
                                '${progress.completed.length} / ${LevelCatalog.count} cleared',
                                levels,
                                summary: true,
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
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Got it'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                summary: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      homeTile(
                        Icons.calendar_today_outlined,
                        'Daily challenge',
                        progress.dailyStars.containsKey(dayKey(DateTime.now()))
                            ? 'Completed today · ${progress.dailyStreak(DateTime.now())} day streak'
                            : 'One puzzle today · +40 coins',
                        openDaily,
                      ),
                      const SizedBox(height: 14),
                      homeTile(
                        Icons.inventory_2_outlined,
                        'Daily Chest',
                        progress.chestUnlocked(DateTime.now())
                            ? '5 hard puzzles · unlocked today'
                            : 'Watch one ad · unlock 5 hard puzzles',
                        openChest,
                      ),
                      const SizedBox(height: 14),
                      homeTile(
                        Icons.park_outlined,
                        'Your garden',
                        '${progress.gardenPoints} points to grow',
                        openGarden,
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
    VoidCallback onTap, {
    bool summary = false,
  }) => Material(
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
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: summary
                    ? 44 * MediaQuery.textScalerOf(context).scale(1)
                    : 0,
              ),
              child: Text(title, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: muted)),
          ],
        ),
      ),
    ),
  );
}
