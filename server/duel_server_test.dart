import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'duel_server.dart';
import '../mobile/lib/game/puzzle.dart';

void check(bool value, String message) { if (!value) throw StateError(message); }
class Peer {
  Peer(this.socket) { subscription = socket.listen((raw) => messages.add(jsonDecode(raw as String) as Map<String, dynamic>)); }
  final WebSocket socket;
  final messages = <Map<String, dynamic>>[];
  late StreamSubscription<dynamic> subscription;
  String? token;
  static Future<Peer> open(int port, [String? token]) async {
    final peer = Peer(await WebSocket.connect('ws://127.0.0.1:$port/duel'));
    peer.send('hello', {if (token != null) 'token': token});
    final hello = await peer.wait((m) => m['type'] == 'hello'); peer.token = hello['token'] as String;
    return peer;
  }
  void send(String type, [Map<String, Object?> extra = const {}]) => socket.add(jsonEncode({'type': type, ...extra}));
  Future<Map<String, dynamic>> wait(bool Function(Map<String, dynamic>) test) async {
    final end = DateTime.now().add(const Duration(seconds: 8));
    while (DateTime.now().isBefore(end)) {
      final matches = messages.where(test); if (matches.isNotEmpty) return matches.last;
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
    throw StateError('Timed out waiting for server event');
  }
  Map<String, dynamic> get state => messages.lastWhere((m) => m['type'] == 'state');
  Future<void> close() async { await socket.close(); await subscription.cancel(); }
}
Puzzle puzzle(Map<String, dynamic> state) {
  final raw = state['puzzle'];
  return Puzzle(0, raw['width'] as int, raw['height'] as int, [for (final a in raw['arrows']) ArrowPath(a['id'] as int, [for (final c in a['cells']) Cell(c[0] as int, c[1] as int)])]);
}
Future<void> main() async {
  final server = DuelServer(duration: const Duration(seconds: 6), countdown: const Duration(milliseconds: 150), grace: const Duration(milliseconds: 250));
  final port = await server.start(port: 0);
  final peers = <Peer>[];
  try {
    final a = await Peer.open(port), b = await Peer.open(port); peers.addAll([a, b]);
    a.send('create'); final waiting = await a.wait((m) => m['phase'] == 'waiting');
    b.send('join', {'code': 'BAD000'}); await b.wait((m) => m['type'] == 'error');
    b.send('join', {'code': waiting['code']});
    final start = await a.wait((m) => m['phase'] == 'playing'); await b.wait((m) => m['phase'] == 'playing');
    check(jsonEncode(start['puzzle']) == jsonEncode(b.state['puzzle']), 'Both players need identical puzzles');
    final initialPuzzle = puzzle(start);
    final blocked = initialPuzzle.arrows.where((a) => !initialPuzzle.canExit(a.id, {})).firstOrNull;
    if (blocked != null) {
      b.send('tap', {'id': blocked.id, 'board': 0, 'seq': 1});
      await b.wait((m) => m['type'] == 'blocked');
      b.send('tap', {'id': initialPuzzle.solution().first, 'board': 0, 'seq': 2});
      await Future<void>.delayed(const Duration(milliseconds: 200));
      check(b.state['score'] == 0 && b.state['mistakes'] == 1, 'Blocked taps must enforce cooldown');
    }
    a.socket.add('{bad json');
    a.send('tap', {'id': -999, 'board': 0, 'seq': 1, 'score': 999});
    await Future<void>.delayed(const Duration(milliseconds: 130));
    final p = puzzle(start);
    final safe = p.solution().first;
    a.send('tap', {'id': safe, 'board': 0, 'seq': 2, 'score': 999});
    await a.wait((m) => m['score'] == 1);
    a.send('tap', {'id': safe, 'board': 0, 'seq': 2});
    a.send('tap', {'id': safe, 'board': 0, 'seq': 3});
    await Future<void>.delayed(const Duration(milliseconds: 230));
    check(a.state['score'] == 1, 'Duplicate/replayed taps must not increase score');
    check(b.state['score'] == 0, 'Opponent progress must be independent');
    final savedToken = a.token!; await a.close(); peers.remove(a);
    final resumed = await Peer.open(port, savedToken); peers.add(resumed);
    await resumed.wait((m) => m['score'] == 1);
    check(resumed.state['removed'].contains(safe), 'Reconnection must restore board and score');
    final result = await resumed.wait((m) => m['phase'] == 'result');
    check(result['result'] == 'You win!', 'Higher score should win at server deadline');
    resumed.send('tap', {'id': p.solution()[1], 'board': 0, 'seq': 5});
    await Future<void>.delayed(const Duration(milliseconds: 150));
    check(resumed.state['score'] == 1, 'Late taps must not alter final score');
    resumed.send('leave'); b.send('leave');
    await resumed.wait((m) => m['phase'] == 'lobby');
    resumed.messages.clear(); b.messages.clear();
    resumed.send('queue'); await resumed.wait((m) => m['phase'] == 'queue'); b.send('queue');
    await resumed.wait((m) => m['phase'] == 'playing');
    await b.close(); peers.remove(b);
    final disconnectResult = await resumed.wait((m) => m['phase'] == 'result');
    check(disconnectResult['result'] == 'You win!' && disconnectResult['reason'] == 'Opponent disconnected', 'Disconnect grace should end in forfeit');
    stdout.writeln('PASS: private room, invalid room, same boards, score authority, duplicate/late taps, reconnect, queue, disconnect forfeit.');
  } finally { for (final peer in peers) { await peer.close(); } await server.close(); }
  final tieServer = DuelServer(duration: const Duration(milliseconds: 250), countdown: Duration.zero);
  final tiePort = await tieServer.start(port: 0);
  final a = await Peer.open(tiePort), b = await Peer.open(tiePort);
  try {
    a.send('queue'); b.send('queue');
    final tied = await a.wait((m) => m['phase'] == 'result');
    check(tied['result'] == 'Draw', 'Equal score must be a draw');
    stdout.writeln('PASS: deadline and draw.');
  } finally { await a.close(); await b.close(); await tieServer.close(); }
}
