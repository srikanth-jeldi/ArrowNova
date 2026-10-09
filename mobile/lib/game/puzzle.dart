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

  bool canExit(int id, Set<int> removed) {
    if (removed.contains(id)) return false;
    final arrow = arrows.firstWhere((a) => a.id == id);
    final occupied = <Cell>{
      for (final a in arrows)
        if (a.id != id && !removed.contains(a.id)) ...a.cells,
    };
    var next = arrow.head + arrow.direction;
    while (contains(next)) {
      if (occupied.contains(next)) return false;
      next = next + arrow.direction;
    }
    return true;
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
  static const count = 500;
  static final Map<int, Puzzle> _cache = {};
  static Puzzle get(int level) {
    if (level < 1 || level > count) throw RangeError.range(level, 1, count);
    return _cache.putIfAbsent(level, () => _generate(level));
  }

  static Puzzle _generate(int level) {
    // Hand-authored lessons: clear exits, a blocker, then a dependency chain.
    if (level <= 3) {
      final paths = level == 1
          ? [
              [const Cell(1, 3), const Cell(1, 2), const Cell(2, 2)],
              [const Cell(5, 3), const Cell(5, 2), const Cell(5, 1)],
              [const Cell(3, 5), const Cell(2, 5), const Cell(1, 5)],
            ]
          : [
              [const Cell(1, 4), const Cell(1, 3), const Cell(2, 3)],
              [const Cell(4, 4), const Cell(4, 3), const Cell(4, 2)],
              if (level == 3)
                [const Cell(3, 1), const Cell(4, 1), const Cell(5, 1)],
              [const Cell(2, 6), const Cell(1, 6), const Cell(1, 5)],
              [const Cell(5, 5), const Cell(5, 6), const Cell(6, 6)],
            ];
      return Puzzle(level, 8, 8, [
        for (var i = 0; i < paths.length; i++) ArrowPath(i, paths[i]),
      ]);
    }
    const directions = [Cell(1, 0), Cell(-1, 0), Cell(0, 1), Cell(0, -1)];
    final random = Random(7429 + level * 101);
    final width = level <= 5 ? 9 : 11;
    final height = level <= 5 ? 11 : 13;
    final target = 10 + min(level, 22);
    Puzzle? best;
    // Only retain paths removable by a complete solver pass. Removing a
    // cyclic remainder cannot invalidate the retained solution order.
    for (var attempt = 0; attempt < 30; attempt++) {
      final used = <Cell>{};
      final arrows = <ArrowPath>[];
      for (var trial = 0; trial < 500 && arrows.length < target; trial++) {
        final start = Cell(random.nextInt(width), random.nextInt(height));
        if (used.contains(start)) continue;
        final cells = [start];
        final length = 3 + random.nextInt(level <= 5 ? 4 : 7);
        for (var step = 1; step < length; step++) {
          final options = directions
              .map((d) => cells.last + d)
              .where(
                (c) =>
                    c.x >= 0 &&
                    c.y >= 0 &&
                    c.x < width &&
                    c.y < height &&
                    !used.contains(c) &&
                    !cells.contains(c),
              )
              .toList();
          if (options.isEmpty) break;
          cells.add(options[random.nextInt(options.length)]);
        }
        if (cells.length < 3) continue;
        used.addAll(cells);
        arrows.add(ArrowPath(arrows.length, cells));
      }
      final candidate = Puzzle(level, width, height, arrows);
      final solved = candidate.solution().toSet();
      final valid = Puzzle(
        level,
        width,
        height,
        arrows.where((a) => solved.contains(a.id)).toList(),
      );
      if (best == null || valid.arrows.length > best.arrows.length) {
        best = valid;
      }
      if (valid.arrows.length >= target - 2) break;
    }
    return best!;
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

  void restart() {
    removed.clear();
    lives = 3;
    mistakes = 0;
    hinted = null;
  }
}
