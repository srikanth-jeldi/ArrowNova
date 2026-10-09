import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../mobile/lib/game/puzzle.dart';

/// Anonymous, unranked duels. Scores, boards and deadlines are server-owned.
class DuelServer {
  DuelServer({
    this.duration = const Duration(seconds: 60),
    this.countdown = const Duration(seconds: 3),
    this.grace = const Duration(seconds: 15),
  });
  final Duration duration, countdown, grace;
  final players = <String, _Player>{};
  final rooms = <String, _Room>{};
  final queue = <_Player>[];
  final random = Random.secure();
  HttpServer? http;
  Timer? ticker;
  String token() => List.generate(
    24,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  Future<int> start({String host = '127.0.0.1', int port = 8788}) async {
    http = await HttpServer.bind(host, port);
    ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => tick());
    http!.listen((request) async {
      if (request.uri.path == '/health') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'ok': true, 'service': 'arrownova-duel'}),
        );
        await request.response.close();
        return;
      }
      if (request.uri.path != '/duel' ||
          !WebSocketTransformer.isUpgradeRequest(request) ||
          players.length >= 500) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }
      try {
        final ws = await WebSocketTransformer.upgrade(request);
        ws.pingInterval = const Duration(seconds: 20);
        _Player? player;
        final helloTimeout = Timer(const Duration(seconds: 10), () {
          if (player == null) ws.close();
        });
        ws.listen(
          (raw) {
            try {
              if (raw is! String || raw.length > 4096) {
                ws.close(1009);
                return;
              }
              final data = jsonDecode(raw);
              if (data is! Map<String, dynamic>) return;
              if (player == null) {
                if (data['type'] != 'hello') return;
                final resume = data['token'];
                final previous = resume is String ? players[resume] : null;
                if (resume != null && previous == null) {
                  ws.add(jsonEncode({'type': 'expired'}));
                  ws.close();
                  return;
                }
                player =
                    previous ??
                    _Player(token(), 'Explorer ${random.nextInt(9000) + 1000}');
                final p = player!;
                final old = p.socket;
                p.socket = ws;
                old?.close();
                p.disconnectedAt = null;
                players[p.token] = p;
                helloTimeout.cancel();
                send(p, {'type': 'hello', 'token': p.token, 'name': p.name});
                snapshot(p);
                return;
              }
              receive(player!, data);
            } catch (_) {
              if (player != null) error(player!, 'Invalid message.');
            }
          },
          onDone: () {
            helloTimeout.cancel();
            if (player case final _Player p) {
              if (identical(p.socket, ws)) {
                p.socket = null;
                p.disconnectedAt = DateTime.now();
                queue.remove(p);
              }
            }
          },
          onError: (_) {
            ws.close();
          },
        );
      } catch (_) {
        /* Failed handshake leaves no player or room. */
      }
    });
    return http!.port;
  }

  void send(_Player p, Map<String, Object?> data) {
    try {
      if (p.socket?.readyState == WebSocket.open)
        p.socket!.add(jsonEncode(data));
    } catch (_) {}
  }

  void error(_Player p, String text) =>
      send(p, {'type': 'error', 'message': text});
  void receive(_Player p, Map<String, dynamic> data) {
    final now = DateTime.now();
    if (now.difference(p.window).inSeconds >= 1) {
      p.window = now;
      p.messages = 0;
    }
    if (++p.messages > 20) {
      error(p, 'Slow down a little.');
      return;
    }
    switch (data['type']) {
      case 'queue':
        if (p.room != null) return;
        queue.removeWhere((other) => other.socket == null || other == p);
        if (queue.isEmpty) {
          queue.add(p);
          snapshot(p);
        } else {
          final other = queue.removeAt(0);
          final room = createRoom(other);
          joinRoom(p, room);
        }
      case 'create':
        if (p.room != null) return;
        queue.remove(p);
        createRoom(p);
        snapshot(p);
      case 'join':
        if (p.room != null) return;
        final room = rooms['${data['code']}'.toUpperCase()];
        if (room == null ||
            room.players.length != 1 ||
            room.players.first.socket == null) {
          error(p, 'Room unavailable. Check the code.');
          return;
        }
        queue.remove(p);
        joinRoom(p, room);
      case 'leave':
        queue.remove(p);
        final room = p.room;
        if (room != null) {
          if (room.players.length == 2 && !room.finished)
            finish(room, reason: 'Opponent left', forfeiter: p);
          room.players.remove(p);
          if (room.players.isEmpty) rooms.remove(room.code);
          p.room = null;
        }
        snapshot(p);
      case 'tap':
        final room = p.room;
        if (room == null || room.finished || room.starts == null) return;
        if (now.isBefore(room.starts!)) return;
        if (!now.isBefore(room.ends!)) {
          finish(room);
          return;
        }
        // Board number + strictly increasing sequence make retries idempotent.
        final seq = data['seq'], id = data['id'];
        if (seq is! int ||
            seq <= p.sequence ||
            id is! int ||
            data['board'] != p.board)
          return;
        p.sequence = seq;
        if (now.difference(p.lastTap).inMilliseconds < 100 ||
            now.isBefore(p.penaltyUntil))
          return;
        p.lastTap = now;
        final puzzle = room.puzzles[p.board % room.puzzles.length];
        if (p.removed.contains(id) || !puzzle.arrows.any((a) => a.id == id))
          return;
        if (puzzle.canExit(id, p.removed)) {
          p.removed.add(id);
          p.score++;
          if (p.removed.length == puzzle.arrows.length) {
            p.board++;
            p.removed.clear();
          }
        } else {
          p.mistakes++;
          p.penaltyUntil = now.add(const Duration(seconds: 1));
          send(p, {'type': 'blocked'});
        }
        for (final player in room.players) {
          snapshot(player);
        }
      case 'sync':
        snapshot(p);
    }
  }

  _Room createRoom(_Player p) {
    String code;
    do {
      code = List.generate(
        6,
        (_) => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[random.nextInt(32)],
      ).join();
    } while (rooms.containsKey(code));
    final room = _Room(
      code,
      List.generate(20, (_) => LevelCatalog.get(4 + random.nextInt(100))),
    );
    rooms[code] = room;
    room.players.add(p);
    p.room = room;
    return room;
  }

  void joinRoom(_Player p, _Room room) {
    room.players.add(p);
    p.room = room;
    room.starts = DateTime.now().add(countdown);
    room.ends = room.starts!.add(duration);
    for (final player in room.players) {
      player.score = 0;
      player.board = 0;
      player.sequence = 0;
      player.mistakes = 0;
      player.removed.clear();
      snapshot(player);
    }
  }

  void finish(_Room room, {String reason = 'Time is up', _Player? forfeiter}) {
    if (room.finished) return;
    room.finished = true;
    room.finishedAt = DateTime.now();
    room.reason = reason;
    if (forfeiter != null) {
      room.winner = room.players.firstWhere((p) => p != forfeiter).token;
    } else if (room.players.length == 2 &&
        room.players[0].score != room.players[1].score) {
      room.winner =
          (room.players[0].score > room.players[1].score
                  ? room.players[0]
                  : room.players[1])
              .token;
    }
    for (final p in room.players) {
      snapshot(p);
    }
  }

  void snapshot(_Player p) {
    final room = p.room;
    if (room == null) {
      send(p, {
        'type': 'state',
        'phase': queue.contains(p) ? 'queue' : 'lobby',
      });
      return;
    }
    final now = DateTime.now();
    final opponent = room.players.where((other) => other != p).firstOrNull;
    final puzzle = room.puzzles[p.board % room.puzzles.length];
    send(p, {
      'type': 'state',
      'phase': room.finished
          ? 'result'
          : room.starts == null
          ? 'waiting'
          : now.isBefore(room.starts!)
          ? 'countdown'
          : 'playing',
      'code': room.code,
      'score': p.score,
      'opponentScore': opponent?.score ?? 0,
      'opponent': opponent?.name,
      'opponentConnected': opponent?.socket != null,
      'remainingMs': room.ends == null
          ? duration.inMilliseconds
          : max(0, room.ends!.difference(now).inMilliseconds),
      'countdownMs': room.starts == null
          ? 0
          : max(0, room.starts!.difference(now).inMilliseconds),
      'penaltyMs': max(0, p.penaltyUntil.difference(now).inMilliseconds),
      'board': p.board,
      'removed': p.removed.toList(),
      'mistakes': p.mistakes,
      'puzzle': {
        'width': puzzle.width,
        'height': puzzle.height,
        'arrows': [
          for (final a in puzzle.arrows)
            {
              'id': a.id,
              'cells': [
                for (final c in a.cells) [c.x, c.y],
              ],
            },
        ],
      },
      'result': room.winner == null
          ? 'Draw'
          : room.winner == p.token
          ? 'You win!'
          : 'Well played!',
      'reason': room.reason,
    });
  }

  void tick() {
    final now = DateTime.now();
    for (final room in rooms.values.toList()) {
      if (!room.finished && room.ends != null) {
        final gone = room.players
            .where(
              (p) =>
                  p.disconnectedAt != null &&
                  now.difference(p.disconnectedAt!) >= grace,
            )
            .firstOrNull;
        if (gone != null) {
          finish(room, reason: 'Opponent disconnected', forfeiter: gone);
        } else if (!now.isBefore(room.ends!)) {
          finish(room);
        }
      }
      if (!room.finished && room.ends != null) {
        for (final p in room.players) {
          snapshot(p);
        }
      }
      final expired =
          room.finishedAt != null &&
              now.difference(room.finishedAt!).inMinutes >= 5 ||
          room.starts == null && now.difference(room.created).inMinutes >= 5;
      if (expired) {
        for (final p in room.players) {
          p.room = null;
          snapshot(p);
        }
        rooms.remove(room.code);
      }
    }
    players.removeWhere(
      (_, p) =>
          p.room == null &&
          p.disconnectedAt != null &&
          now.difference(p.disconnectedAt!).inMinutes >= 1,
    );
  }

  Future<void> close() async {
    ticker?.cancel();
    for (final p in players.values) {
      await p.socket?.close();
    }
    await http?.close(force: true);
  }
}

class _Player {
  _Player(this.token, this.name);
  final String token, name;
  WebSocket? socket;
  _Room? room;
  DateTime? disconnectedAt;
  DateTime window = DateTime.now(),
      lastTap = DateTime.fromMillisecondsSinceEpoch(0),
      penaltyUntil = DateTime.fromMillisecondsSinceEpoch(0);
  int messages = 0, score = 0, mistakes = 0, board = 0, sequence = 0;
  final removed = <int>{};
}

class _Room {
  _Room(this.code, this.puzzles);
  final String code;
  final List<Puzzle> puzzles;
  final players = <_Player>[];
  final created = DateTime.now();
  DateTime? starts, ends, finishedAt;
  bool finished = false;
  String? winner;
  String reason = '';
}

Future<void> main() async {
  final server = DuelServer();
  final host = Platform.environment['HOST'] ?? '127.0.0.1';
  final port = await server.start(
    host: host,
    port: int.tryParse(Platform.environment['PORT'] ?? '') ?? 8788,
  );
  stdout.writeln('ArrowNova duel server listening on $host:$port');
  ProcessSignal.sigint.watch().listen((_) async {
    await server.close();
    exit(0);
  });
}
