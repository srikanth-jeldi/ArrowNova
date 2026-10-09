import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/feedback_service.dart';
import '../core/progress_store.dart';
import '../game/board.dart';
import '../game/puzzle.dart';
import '../ui.dart';
import 'duel_client.dart';

class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key, required this.progress});
  final PlayerProgress progress;
  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  final client = DuelClient();
  final roomCode = TextEditingController();
  late final TextEditingController endpoint;
  final feedback = FeedbackService();
  int lastBlocked = 0, lastScore = 0;
  DateTime lastTap = DateTime.fromMillisecondsSinceEpoch(0);
  @override
  void initState() {
    super.initState();
    endpoint = TextEditingController(text: client.endpoint);
    client.addListener(update);
    unawaited(client.connect());
  }

  void update() {
    final score = client.state['score'] as int? ?? 0;
    if (client.blockedEvents > lastBlocked || score > lastScore) {
      unawaited(
        feedback.play(
          client.blockedEvents > lastBlocked ? 'blocked' : 'clear',
          sound: widget.progress.sound,
          haptics: widget.progress.haptics,
        ),
      );
    }
    lastBlocked = client.blockedEvents;
    lastScore = score;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    client.removeListener(update);
    client.dispose();
    endpoint.dispose();
    roomCode.dispose();
    feedback.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    final phase = client.state['phase'];
    if (['playing', 'countdown'].contains(phase)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave this duel?'),
          content: const Text('Leaving gives your opponent the win.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave duel'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  GameSession board() {
    final raw = client.state['puzzle'] as Map<String, dynamic>;
    final puzzle = Puzzle(0, raw['width'] as int, raw['height'] as int, [
      for (final a in raw['arrows'] as List)
        ArrowPath(a['id'] as int, [
          for (final c in a['cells'] as List) Cell(c[0] as int, c[1] as int),
        ]),
    ]);
    return GameSession(puzzle)
      ..removed.addAll((client.state['removed'] as List).cast<int>());
  }

  @override
  Widget build(BuildContext context) {
    final s = client.state;
    final phase = s['phase'];
    final playing = phase == 'playing' || phase == 'countdown';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: leave,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Live puzzle duel'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: playing
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _score('You', s['score']),
                            Text(
                              '${((s['remainingMs'] as int? ?? 0) / 1000).ceil().clamp(0, 60)}s',
                              style: const TextStyle(fontSize: 35, color: gold),
                            ),
                            _score('Opponent', s['opponentScore']),
                          ],
                        ),
                      ),
                      Text(
                        !client.online
                            ? 'Reconnecting… clock keeps running'
                            : s['opponentConnected'] == false
                            ? 'Opponent reconnecting…'
                            : phase == 'countdown'
                            ? 'Ready in ${((s['countdownMs'] as int) / 1000).ceil()}'
                            : (s['penaltyMs'] as int? ?? 0) > 0
                            ? 'Blocked · wait one second'
                            : 'Clear arrows to score. Same boards for both players.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: gold),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7F7),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: AbsorbPointer(
                            absorbing:
                                !client.online ||
                                phase != 'playing' ||
                                (s['penaltyMs'] as int? ?? 0) > 0,
                            child: ArrowBoard(
                              game: board(),
                              onTap: (id) {
                                final now = DateTime.now();
                                if (id != null &&
                                    now.difference(lastTap).inMilliseconds >=
                                        150) {
                                  lastTap = now;
                                  client.tap(id);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'One clear arrow = one point · No hints in duels',
                          style: TextStyle(color: muted),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Icon(Icons.bolt_rounded, size: 68, color: gold),
                      const SizedBox(height: 14),
                      Text(
                        phase == 'result'
                            ? '${s['result']}'
                            : 'A little friendly rivalry',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 12),
                      if (phase == 'result') ...[
                        Text(
                          '${s['score']} — ${s['opponentScore']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 45, color: gold),
                        ),
                        Text(
                          '${s['reason']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: muted),
                        ),
                        const SizedBox(height: 20),
                        GoldButton(
                          label: 'Play another duel',
                          onPressed: client.online
                              ? () => client.send('leave')
                              : null,
                        ),
                      ] else if (phase == 'waiting' || phase == 'queue') ...[
                        Text(
                          phase == 'waiting'
                              ? 'Share this room code'
                              : 'Looking for another player…',
                          textAlign: TextAlign.center,
                        ),
                        if (phase == 'waiting') ...[
                          SelectableText(
                            '${s['code']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'ArrowNovaSans',
                              fontSize: 38,
                              color: gold,
                              letterSpacing: 5,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => Clipboard.setData(
                              ClipboardData(text: '${s['code']}'),
                            ),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy code'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Text(
                          'The match starts when a second player joins. No bots are used.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted),
                        ),
                        TextButton(
                          onPressed: client.online
                              ? () => client.send('leave')
                              : null,
                          child: const Text('Cancel'),
                        ),
                      ] else ...[
                        const Text(
                          '60 seconds. Clear more arrows than your opponent. Blocked taps pause your moves for one second. Equal scores are a draw.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted, height: 1.6),
                        ),
                        const SizedBox(height: 22),
                        GoldButton(
                          label: 'Find opponent',
                          icon: Icons.people_alt_outlined,
                          onPressed: client.online
                              ? () => client.send('queue')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: client.online
                              ? () => client.send('create')
                              : null,
                          child: const Text('Create friend room'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: roomCode,
                          maxLength: 6,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Friend room code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        FilledButton(
                          onPressed: client.online
                              ? () => client.send('join', {
                                  'code': roomCode.text.trim().toUpperCase(),
                                })
                              : null,
                          child: const Text('Join friend'),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Text(
                        client.online
                            ? 'Connected as ${client.name} · Unranked guest duel'
                            : client.status == 'connecting'
                            ? 'Connecting…'
                            : 'Not connected',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: muted),
                      ),
                      if (client.message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            client.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: gold),
                          ),
                        ),
                      if (!client.online)
                        TextButton(
                          onPressed: () => client.connect(),
                          child: const Text('Retry connection'),
                        ),
                      if (phase == 'lobby')
                        ExpansionTile(
                          title: const Text('Server connection'),
                          children: [
                            const Text(
                              'Both players must connect to the same server.',
                              style: TextStyle(color: muted),
                            ),
                            TextField(
                              controller: endpoint,
                              decoration: const InputDecoration(
                                labelText: 'Server address',
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  client.connect(endpoint.text.trim()),
                              child: const Text('Connect'),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _score(String label, Object? score) => Column(
    children: [
      Text(label, style: const TextStyle(color: muted)),
      Text('$score', style: const TextStyle(fontSize: 30, color: gold)),
    ],
  );
}
