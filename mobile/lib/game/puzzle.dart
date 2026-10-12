import 'dart:math';

class Cell {
  const Cell(this.x, this.y);
  final int x, y;
  Cell operator +(Cell other) => Cell(x + other.x, y + other.y);
  Cell operator -(Cell other) => Cell(x - other.x, y - other.y);
  @override
  bool operator ==(Object other) =>
      other is Cell && x == other.x && y == other.y;
  @override
  int get hashCode => Object.hash(x, y);
}

class ArrowPath {
  ArrowPath(this.id, List<Cell> cells) : cells = List.unmodifiable(cells);
  final int id;

  /// Tail to head. Each consecutive cell is one orthogonal step.
  final List<Cell> cells;
  Cell get head => cells.last;
  Cell get direction => head - cells[cells.length - 2];
}

class Puzzle {
  Puzzle(this.level, this.width, this.height, List<ArrowPath> arrows)
    : arrows = List.unmodifiable(arrows);
  final int level, width, height;
  final List<ArrowPath> arrows;
  bool contains(Cell c) => c.x >= 0 && c.y >= 0 && c.x < width && c.y < height;

  // Geometry is immutable. Cache blockers once instead of rebuilding every
  // occupied cell on every tap/hint in a 200-arrow board.
  late final Map<int, Set<int>> _blockers = _findBlockers();
  Map<int, Set<int>> _findBlockers() {
    final owners = <Cell, int>{
      for (final a in arrows)
        for (final cell in a.cells) cell: a.id,
    };
    return {
      for (final arrow in arrows)
        arrow.id: (() {
          final blockers = <int>{};
          var next = arrow.head + arrow.direction;
          while (contains(next)) {
            final owner = owners[next];
            if (owner != null && owner != arrow.id) blockers.add(owner);
            next = next + arrow.direction;
          }
          return blockers;
        })(),
    };
  }

  bool canExit(int id, Set<int> removed) =>
      !removed.contains(id) &&
      _blockers.containsKey(id) &&
      _blockers[id]!.every(removed.contains);

  int get dependencyDepth {
    final depths = <int, int>{};
    int visit(int id) => depths.putIfAbsent(
      id,
      () =>
          1 +
          _blockers[id]!.fold<int>(
            0,
            (depth, blocker) => max(depth, visit(blocker)),
          ),
    );
    return arrows.fold<int>(0, (depth, arrow) => max(depth, visit(arrow.id)));
  }

  List<int> solution([Set<int> removed = const {}]) {
    final cleared = {...removed};
    final order = <int>[];
    while (true) {
      final available = arrows.where((a) => canExit(a.id, cleared)).toList();
      if (available.isEmpty) break;
      for (final arrow in available) {
        cleared.add(arrow.id);
        order.add(arrow.id);
      }
    }
    return order;
  }
}

class LevelCatalog {
  static const count = 6000;
  static final Map<int, Puzzle> _cache = {};
  static bool isHard(int level) => level % 10 == 0;
  // Preserve released boards and saved stars for levels 1–800. Later boards
  // stay at 200 arrows, with fresh seeds and a hard puzzle every tenth level.
  static int arrowCount(int level) =>
      30 + (level.clamp(1, 800) - 1) * 170 ~/ 799;
  static Puzzle get(int level) {
    if (level < 1 || level > count) throw RangeError.range(level, 1, count);
    if (_cache.containsKey(level)) return _cache[level]!;
    if (_cache.length >= 24) _cache.remove(_cache.keys.first);
    return _cache[level] = _generate(level);
  }

  static const _directions = [Cell(1, 0), Cell(-1, 0), Cell(0, 1), Cell(0, -1)];

  static String shapeName(int level) =>
      ['Circle', 'Diamond', 'Shield', 'Leaf'][(level - 1) % 4];

  static Set<Cell> silhouette(int level, int width, int height) {
    final cells = <Cell>{};
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final nx = (x - (width - 1) / 2) / (width / 2);
        final ny = (y - (height - 1) / 2) / (height / 2);
        final inside = switch ((level - 1) % 4) {
          0 => nx * nx + ny * ny <= 1,
          1 => nx.abs() + ny.abs() <= 1.03,
          2 => nx.abs() <= (ny < .2 ? .92 : .92 - (ny - .2) * .9),
          _ => nx * nx + ny * ny + .45 * nx * ny <= .95,
        };
        if (inside) cells.add(Cell(x, y));
      }
    }
    return cells;
  }

  static Puzzle _generate(int level) {
    final random = Random(7429 + level * 101);
    final target = arrowCount(level);
    final fill = (level - 1) % 4 == 1 ? .52 : .78;
    final width = sqrt(target * 10 / (fill * 1.2)).ceil();
    final height = (width * 1.2).round();
    final mask = silhouette(level, width, height);
    Puzzle? best;
    var bestScore = -double.infinity;
    for (var attempt = 0; attempt < 32; attempt++) {
      final free = {...mask};
      final arrows = <ArrowPath>[];
      while (arrows.length < target) {
        // Isolated single cells cannot form an arrow. Drop these small crumbs
        // rather than drawing misleading one-point paths.
        free.removeAll(
          free
              .where((c) => !_directions.any((d) => free.contains(c + d)))
              .toList(),
        );
        final left = target - arrows.length;
        if (free.length < left * 2) break;
        final rowMin = List.filled(height, width),
            rowMax = List.filled(height, -1);
        final colMin = List.filled(width, height),
            colMax = List.filled(width, -1);
        for (final c in free) {
          rowMin[c.y] = min(rowMin[c.y], c.x);
          rowMax[c.y] = max(rowMax[c.y], c.x);
          colMin[c.x] = min(colMin[c.x], c.y);
          colMax[c.x] = max(colMax[c.x], c.y);
        }
        final heads = <(Cell, Cell)>[];
        for (var y = 0; y < height; y++) {
          for (final (x, d) in [
            (rowMin[y], const Cell(-1, 0)),
            (rowMax[y], const Cell(1, 0)),
          ]) {
            final c = Cell(x, y);
            if (free.contains(c) && free.contains(c - d)) heads.add((c, d));
          }
        }
        for (var x = 0; x < width; x++) {
          for (final (y, d) in [
            (colMin[x], const Cell(0, -1)),
            (colMax[x], const Cell(0, 1)),
          ]) {
            final c = Cell(x, y);
            if (free.contains(c) && free.contains(c - d)) heads.add((c, d));
          }
        }
        if (heads.isEmpty) break;
        heads.shuffle(random);
        if (isHard(level)) {
          heads.sort(
            (a, b) => (mask.contains(b.$1 + b.$2) ? 1 : 0).compareTo(
              mask.contains(a.$1 + a.$2) ? 1 : 0,
            ),
          );
        }
        final average = free.length / left;
        final category = arrows.length % 5;
        final wanted =
            (category == 0
                    ? 3 + random.nextInt(2)
                    : category == 1
                    ? average * (3.3 + random.nextDouble())
                    : average * (.7 + random.nextDouble() * .6))
                .round()
                .clamp(2, min(64, free.length - 2 * (left - 1)));
        List<Cell>? chosen;
        var pathScore = -double.infinity;
        for (final (head, direction) in heads.take(24)) {
          final path = [head, head - direction];
          final used = path.toSet();
          var heading = Cell(-direction.x, -direction.y);
          var run = 1;
          var turns = 0;
          while (path.length < wanted) {
            final options = _directions
                .where(
                  (d) =>
                      free.contains(path.last + d) &&
                      !used.contains(path.last + d),
                )
                .toList();
            if (options.isEmpty) break;
            final straight = options.contains(heading);
            Cell nextDirection;
            if (straight && (run < 3 || random.nextDouble() < .8)) {
              nextDirection = heading;
            } else {
              final bends = options.where((d) => d != heading).toList();
              if (bends.isEmpty) {
                nextDirection = heading;
              } else if (run < 2 && path.length > 2) {
                break;
              } else {
                nextDirection = bends[random.nextInt(bends.length)];
              }
            }
            if (nextDirection != heading) {
              turns++;
              run = 0;
            }
            if (turns > 5) break;
            heading = nextDirection;
            run++;
            path.add(path.last + heading);
            used.add(path.last);
          }
          final score =
              (mask.contains(head + direction)
                  ? (isHard(level) ? 2.0 : .5)
                  : 0) -
              (path.length - wanted).abs().toDouble() -
              turns * .12 +
              random.nextDouble() * .2;
          if (score > pathScore) {
            chosen = path;
            pathScore = score;
          }
        }
        if (chosen == null) break;
        arrows.add(ArrowPath(arrows.length, chosen.reversed.toList()));
        free.removeAll(chosen);
      }
      if (arrows.length != target) continue;
      final candidate = Puzzle(level, width, height, arrows);
      final coverage =
          arrows.fold<int>(0, (sum, a) => sum + a.cells.length) / mask.length;
      final short = arrows.where((a) => a.cells.length <= 4).length;
      final long = arrows.where((a) => a.cells.length >= 18).length;
      final blocked =
          arrows.where((a) => !candidate.canExit(a.id, {})).length / target;
      final depth = candidate.dependencyDepth;
      if (coverage < .80 ||
          short < (target * .12).floor() ||
          long < 2 ||
          !arrows.any((a) => a.cells.length >= 24) ||
          blocked < (isHard(level) ? .7 : .4) ||
          (isHard(level) && depth < 8)) {
        continue;
      }
      final score =
          (isHard(level) ? depth * 1.5 : 0) +
          coverage * 100 +
          min(short, target * .2) +
          min(long, target * .12) * 2 +
          blocked * (isHard(level) ? 20 : 4);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
      if (coverage >= .87 &&
          short >= target * .15 &&
          long >= max(2, target * .08) &&
          blocked >= (isHard(level) ? .75 : .4)) {
        break;
      }
    }
    if (best == null) throw StateError('Could not build level $level');
    return best;
  }
}

class TrainingCatalog {
  static Puzzle get(int level) {
    // Two separate practice boards: clear exits, then a blocker.
    if (level >= 1 && level <= 2) {
      final paths = level == 1
          ? [
              [const Cell(1, 3), const Cell(1, 2), const Cell(2, 2)],
              [const Cell(5, 3), const Cell(5, 2), const Cell(5, 1)],
              [const Cell(3, 5), const Cell(2, 5), const Cell(1, 5)],
            ]
          : [
              [const Cell(1, 4), const Cell(1, 3), const Cell(2, 3)],
              [const Cell(4, 4), const Cell(4, 3), const Cell(4, 2)],
              [const Cell(2, 6), const Cell(1, 6), const Cell(1, 5)],
              [const Cell(5, 5), const Cell(5, 6), const Cell(6, 6)],
            ];
      return Puzzle(level, 8, 8, [
        for (var i = 0; i < paths.length; i++) ArrowPath(i, paths[i]),
      ]);
    }
    throw RangeError.range(level, 1, 2);
  }
}

enum TapResult { cleared, blocked, ignored }

class GameSession {
  GameSession(this.puzzle);
  final Puzzle puzzle;
  final Set<int> removed = {};
  int lives = 3;
  int mistakes = 0;
  int? hinted;
  bool get won => removed.length == puzzle.arrows.length;
  bool get lost => lives == 0;
  String get layoutKey => puzzle.arrows
      .map((a) => '${a.id}:${a.cells.map((c) => '${c.x},${c.y}').join(';')}')
      .join('|');
  Map<String, dynamic> snapshot(int elapsedMs) => {
    'layout': layoutKey,
    'removed': removed.toList(),
    'lives': lives,
    'mistakes': mistakes,
    'hinted': hinted,
    'elapsedMs': elapsedMs,
  };
  int restore(Map<String, dynamic>? data) {
    if (data == null ||
        data['layout'] != layoutKey ||
        data['lives'] is! int ||
        data['mistakes'] is! int ||
        data['removed'] is! List) {
      return 0;
    }
    final ids = (data['removed'] as List).whereType<int>().toSet();
    if (ids.length >= puzzle.arrows.length ||
        ids.any((id) => !puzzle.arrows.any((a) => a.id == id)) ||
        data['lives'] < 0 ||
        data['lives'] > 3 ||
        data['mistakes'] < 0) {
      return 0;
    }
    removed.addAll(ids);
    lives = data['lives'];
    mistakes = data['mistakes'];
    final savedHint = data['hinted'];
    if (savedHint is int &&
        !removed.contains(savedHint) &&
        puzzle.arrows.any((a) => a.id == savedHint)) {
      hinted = savedHint;
    }
    return data['elapsedMs'] is int
        ? (data['elapsedMs'] as int).clamp(0, 604800000)
        : 0;
  }

  TapResult tap(int? id) {
    if (id == null ||
        won ||
        lost ||
        removed.contains(id) ||
        !puzzle.arrows.any((a) => a.id == id)) {
      return TapResult.ignored;
    }
    if (!puzzle.canExit(id, removed)) {
      lives--;
      mistakes++;
      return TapResult.blocked;
    }
    removed.add(id);
    if (hinted == id) hinted = null;
    return TapResult.cleared;
  }

  int? hint() {
    if (lost || won) return null;
    final solution = puzzle.solution(removed);
    return hinted = solution.isEmpty ? null : solution.first;
  }

  /// Restore hearts while retaining cleared paths and scoring mistakes.
  bool revive() {
    if (!lost || won) return false;
    lives = 3;
    return true;
  }

  void restart() {
    removed.clear();
    lives = 3;
    mistakes = 0;
    hinted = null;
  }
}
