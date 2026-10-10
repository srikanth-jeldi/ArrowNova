// Compile with `dart compile exe tool/audit_levels.dart -o build/audit_levels.exe`.
// Run the executable to validate the entire shipping catalog with bounded memory.
import 'dart:io';
import 'dart:isolate';

import 'package:arrownova/game/puzzle.dart';

void check(bool condition, int level, String message) {
  if (!condition) throw StateError('Level $level: $message');
}

Future<void> worker((SendPort, int, int) args) async {
  final (port, start, stride) = args;
  for (var n = start; n <= LevelCatalog.count; n += stride) {
    try {
      final p = LevelCatalog.get(n);
      check(p.arrows.length == LevelCatalog.arrowCount(n), n, 'arrow count');
      final cells = <Cell>{};
      final mask = LevelCatalog.silhouette(n, p.width, p.height);
      for (final a in p.arrows) {
        check(a.cells.length >= 2, n, 'short path');
        for (var i = 0; i < a.cells.length; i++) {
          final c = a.cells[i];
          check(mask.contains(c) && cells.add(c), n, 'overlap / silhouette');
          if (i > 0) {
            final d = c - a.cells[i - 1];
            check(d.x.abs() + d.y.abs() == 1, n, 'disconnected path');
          }
        }
      }
      check(cells.length / mask.length >= .8, n, 'coverage');
      check(
        p.arrows.where((a) => a.cells.length <= 4).length >=
            (p.arrows.length * .12).floor(),
        n,
        'short path variety',
      );
      check(
        p.arrows.where((a) => a.cells.length >= 18).length >= 2 &&
            p.arrows.any((a) => a.cells.length >= 24),
        n,
        'long path variety',
      );
      final blocked =
          p.arrows.where((a) => !p.canExit(a.id, {})).length / p.arrows.length;
      check(blocked >= (LevelCatalog.isHard(n) ? .7 : .4), n, 'dependencies');
      final solution = p.solution();
      check(solution.length == p.arrows.length, n, 'unsolvable');
      if (LevelCatalog.isHard(n)) {
        check(p.dependencyDepth >= 8, n, 'hard depth');
      }
      final game = GameSession(p);
      for (final id in solution) {
        check(game.tap(id) == TapResult.cleared, n, 'invalid solution');
      }
      check(game.won && game.lives == 3, n, 'completion');
      // Exact geometry string, not a probabilistic hash, for cross-worker uniqueness.
      final fingerprint = p.arrows
          .map((a) => a.cells.map((c) => '${c.x},${c.y}').join(':'))
          .join('|');
      port.send((n, fingerprint));
    } catch (e) {
      port.send('FAIL $n: $e');
      return;
    }
  }
  port.send('done');
}

Future<void> main() async {
  final timer = Stopwatch()..start(), port = ReceivePort();
  final fingerprints = <String>{};
  final workers = <Isolate>[];
  final concurrency = Platform.numberOfProcessors.clamp(1, 4);
  var completed = 0, finished = 0;
  for (var i = 1; i <= concurrency; i++) {
    workers.add(await Isolate.spawn(worker, (port.sendPort, i, concurrency)));
  }
  await for (final message in port) {
    if (message is String) {
      if (message != 'done') {
        stderr.writeln(message);
        exitCode = 1;
        break;
      }
      if (++finished == concurrency) break;
    } else {
      final (level, fingerprint) = message as (int, String);
      if (!fingerprints.add(fingerprint)) {
        stderr.writeln('Duplicate level $level');
        exitCode = 1;
        break;
      }
      completed++;
      if (completed % 100 == 0) {
        stdout.writeln(
          '$completed/${LevelCatalog.count} validated (${timer.elapsed.inSeconds}s)',
        );
      }
    }
  }
  for (final isolate in workers) {
    isolate.kill(priority: Isolate.immediate);
  }
  port.close();
  if (completed != LevelCatalog.count) exitCode = 1;
  stdout.writeln(
    'Validated $completed unique, solvable boards; elapsed ${timer.elapsed}; exit $exitCode',
  );
}
