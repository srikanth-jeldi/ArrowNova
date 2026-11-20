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
  Puzzle(
    this.level,
    this.width,
    this.height,
    List<ArrowPath> arrows, {
    this.rescueCageIds = const {},
  }) : arrows = List.unmodifiable(arrows);
  final int level, width, height;
  final List<ArrowPath> arrows;
  final Set<int> rescueCageIds;
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
  static bool isHard(int level) =>
      level > 30 && level <= count && level % 10 == 0;
  // Introduce short, smaller puzzles first. Levels 31–800 keep released boards.
  // Later boards
  // stay at 200 arrows, with fresh seeds and a hard puzzle every tenth level.
  static int arrowCount(int level) => level > count
      ? EndlessCatalog.arrowCount(level)
      : level <= 30
      ? 5 + (level.clamp(1, 30) - 1) * 25 ~/ 29
      : 30 + (level.clamp(1, 800) - 1) * 170 ~/ 799;
  static Puzzle get(int level, {bool legacy = false}) {
    if (level < 1) throw RangeError.value(level, 'level');
    if (level > count) return EndlessCatalog.get(level);
    final key = legacy && level <= 30 ? -level : level;
    if (_cache.containsKey(key)) return _cache[key]!;
    if (_cache.length >= 24) _cache.remove(_cache.keys.first);
    return _cache[key] = _generate(level, legacy: legacy);
  }

  static Puzzle resume(int level, Map<String, dynamic>? run) {
    final current = get(level);
    if (level <= 30 &&
        run != null &&
        run['layout'] != GameSession(current).layoutKey) {
      final previousCircuit = _circuit(level);
      if (run['layout'] == GameSession(previousCircuit).layoutKey) {
        return previousCircuit;
      }
      final lanes = _gentle(level, endless: false);
      if (run['layout'] == GameSession(lanes).layoutKey) return lanes;
      final previous = get(level, legacy: true);
      if (run['layout'] == GameSession(previous).layoutKey) return previous;
    }
    return current;
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

  // Independent lanes create short, visible removal chains without cycles.
  // The seed is tied to the round, so retry and resume always use the same board.
  static Puzzle _gentle(
    int level, {
    required bool endless,
    bool rescue = false,
  }) {
    final random = Random(
      7429 + level * 101 + (endless ? 918273 : 0) + (rescue ? 5210017 : 0),
    );
    final rescueProgress =
        (level.clamp(1, RescueCatalog.count) - 1) / (RescueCatalog.count - 1);
    final count = rescue
        ? 20 + (60 * sqrt(rescueProgress)).round()
        : endless
        ? EndlessCatalog.arrowCount(level)
        : arrowCount(level);
    if (rescue && level == 1) return _legacyRescueOpeningMaze(level);
    if (rescue && level >= 2) {
      // Let later Rescue missions grow from increasingly dense hard boards.
      final sourceLevel = level <= 10
          ? const [400, 480, 560, 640, 720, 800, 960, 1040, 1120][level - 2]
          : min(LevelCatalog.count, 1120 + (level - 10) * 20);
      final classicHard = get(sourceLevel);
      final centerX = classicHard.width ~/ 2;
      final centerY = classicHard.height ~/ 2;
      final protected = {
        for (var y = centerY - 6; y <= centerY + 6; y++)
          for (var x = centerX - 7; x <= centerX + 5; x++) Cell(x, y),
      };
      final cage = <List<Cell>>[
        [for (var x = centerX - 6; x <= centerX + 3; x++) Cell(x, centerY - 5)],
        [for (var y = centerY - 4; y <= centerY + 4; y++) Cell(centerX + 4, y)],
        [for (var x = centerX + 3; x >= centerX - 5; x--) Cell(x, centerY + 5)],
        [for (var y = centerY + 4; y >= centerY - 4; y--) Cell(centerX - 6, y)],
        [Cell(centerX + 4, centerY - 5), Cell(centerX + 5, centerY - 5)],
        [Cell(centerX + 4, centerY + 4), Cell(centerX + 4, centerY + 5)],
      ];
      final cageExitRays = <Cell>{};
      for (final path in cage.take(4)) {
        final direction = path.last - path[path.length - 2];
        var cell = path.last + direction;
        while (classicHard.contains(cell)) {
          cageExitRays.add(cell);
          cell = cell + direction;
        }
      }
      final paths = <ArrowPath>[];
      for (final arrow in classicHard.arrows) {
        if (arrow.cells.any(protected.contains) ||
            arrow.cells.any(cageExitRays.contains)) {
          continue;
        }
        paths.add(ArrowPath(paths.length, arrow.cells));
      }
      final cageStart = paths.length;
      paths.addAll([
        for (var i = 0; i < 4; i++) ArrowPath(cageStart + i, cage[i]),
      ]);
      final allCells = paths.expand((path) => path.cells);
      final minX = allCells.map((cell) => cell.x).reduce(min);
      final minY = allCells.map((cell) => cell.y).reduce(min);
      final maxX = allCells.map((cell) => cell.x).reduce(max);
      final maxY = allCells.map((cell) => cell.y).reduce(max);
      // Match the portrait reference by using the source board's vertical
      // space fully instead of leaving broad top and bottom margins.
      const verticalScale = 4 / 3;
      final scaledPaths = <ArrowPath>[];
      for (final path in paths) {
        final cells = <Cell>[];
        for (final cell in path.cells) {
          final next = Cell(
            cell.x - minX,
            ((cell.y - minY) * verticalScale).round(),
          );
          if (cells.isNotEmpty && cells.last.x == next.x) {
            final step = (next.y - cells.last.y).sign.toInt();
            var y = cells.last.y + step;
            while (y != next.y) {
              cells.add(Cell(next.x, y));
              y += step;
            }
          }
          cells.add(next);
        }
        scaledPaths.add(ArrowPath(path.id, cells));
      }
      return Puzzle(
        level,
        maxX - minX + 1,
        ((maxY - minY) * verticalScale).round() + 1,
        scaledPaths,
        rescueCageIds: {cageStart, cageStart + 1, cageStart + 2, cageStart + 3},
      );
    }
    if (rescue && level <= 10) {
      // Start at Classic level-10 circuit difficulty, with the animal
      // enclosed by bent arrows on every side from the first mission.
      const width = 24, height = 24;
      final centerX = width ~/ 2, centerY = height ~/ 2;
      final cage = <List<Cell>>[
        [for (var x = centerX - 4; x <= centerX + 1; x++) Cell(x, centerY - 3)],
        [for (var y = centerY - 2; y <= centerY + 1; y++) Cell(centerX + 2, y)],
        [for (var x = centerX + 1; x >= centerX - 2; x--) Cell(x, centerY + 3)],
        [for (var y = centerY + 2; y >= centerY - 1; y--) Cell(centerX - 4, y)],
        [Cell(centerX + 2, centerY - 3), Cell(centerX + 3, centerY - 3)],
        [Cell(centerX + 2, centerY + 2), Cell(centerX + 2, centerY + 3)],
      ];
      // This six-cell bent path is the same circuit motif used by Classic 10.
      const circuit = [
        Cell(0, 0),
        Cell(0, 1),
        Cell(1, 1),
        Cell(2, 1),
        Cell(2, 0),
        Cell(3, 0),
      ];
      final top = <List<Cell>>[
        for (final x in [5, 9, 13])
          if (x == 9 || x == 13)
            [for (final c in circuit) Cell(x + c.y, 3 + c.x)]
          else
            [for (final c in circuit) Cell(x + c.y, 1 + 3 - c.x)],
        for (final x in [1, 17])
          [for (final c in circuit) Cell(x + c.y, 1 + 3 - c.x)],
      ];
      final bottom = <List<Cell>>[
        for (final x in [5, 9, 13])
          [for (final c in circuit) Cell(x + c.y, 17 + c.x)],
        for (final x in [1, 17])
          [for (final c in circuit) Cell(x + c.y, 17 + c.x)],
      ];
      final left = <List<Cell>>[
        for (final y in [5, 9, 11, 14])
          if (y == 9 || y == 11)
            [for (final c in circuit) Cell(1 + c.x, y + c.y)]
          else
            [for (final c in circuit) Cell(1 + 3 - c.x, y + c.y)],
      ];
      final right = <List<Cell>>[
        for (final y in [5, 9, 11, 14])
          if (y == 14)
            [for (final c in circuit) Cell(18 + 3 - c.x, y + c.y)]
          else
            [for (final c in circuit) Cell(18 + c.x, y + c.y)],
      ];
      final ring = [
        ...top.take(3),
        ...bottom.take(3),
        ...left.take(4),
        ...right.take(4),
        ...top.skip(3),
        ...bottom.skip(3),
      ];
      final allPaths = [
        ...cage,
        for (var i = 0; i < count - cage.length; i++) ring[i],
      ];
      return Puzzle(
        level,
        width,
        height,
        [
          for (var id = 0; id < allPaths.length; id++)
            ArrowPath(id, allPaths[id]),
        ],
        rescueCageIds: const {0, 1, 2, 3},
      );
    }
    final chain = rescue
        ? (count >= 40 ? 5 : 4)
        : level <= 5
        ? 2
        : level <= 10
        ? 3
        : level <= 20
        ? 4
        : 5;
    final fillerCount = rescue ? count - 6 : count;
    final rows = max(1, (fillerCount / chain).ceil());
    // Animal rescues keep a deliberate empty pocket near the centre so the
    // trapped animal is visibly framed by arrows instead of hidden beneath a
    // path. Normal Classic/Endless lane layouts remain compact.
    const rescueGap = 12;
    final width = chain * 8 + 2 + (rescue ? rescueGap : 0);
    final height = rows * 4 + 2 + (rescue ? rescueGap : 0);
    final paths = <ArrowPath>[];
    for (var row = 0; row < rows; row++) {
      final left = random.nextBool();
      final inRow = min(chain, fillerCount - paths.length);
      final y =
          1 + row * 4 + (rescue && row >= (rows + 1) ~/ 2 ? rescueGap : 0);
      for (var col = 0; col < inRow; col++) {
        final x =
            1 +
            col * 8 +
            (rescue && col >= (chain + 1) ~/ 2 ? rescueGap : 0) +
            random.nextInt(2);
        final length = 3 + random.nextInt(level <= 10 ? 2 : 3);
        final cells = <Cell>[
          if (random.nextBool()) Cell(x, y + 1),
          for (var dx = 0; dx < length; dx++) Cell(x + dx, y),
        ];
        paths.add(
          ArrowPath(
            paths.length,
            cells.map((c) => left ? Cell(width - 1 - c.x, c.y) : c).toList(),
          ),
        );
      }
    }
    // Use portrait geometry so the paths remain readable on a phone.
    final portrait = width > height;
    final boardWidth = portrait ? height : width;
    final boardHeight = portrait ? width : height;
    final orientedPaths = portrait
        ? [
            for (final path in paths)
              ArrowPath(
                path.id,
                path.cells.map((c) => Cell(c.y, width - 1 - c.x)).toList(),
              ),
          ]
        : paths;
    if (!rescue) return Puzzle(level, boardWidth, boardHeight, orientedPaths);

    // Four of the playable paths form the animal's cage. Two outside arrows
    // block exits from its top and right sides, so the player must clear those
    // blockers before opening the cage. The remaining paths stay outside the
    // central pocket reserved above.
    final centerX = boardWidth ~/ 2;
    final centerY = boardHeight ~/ 2;
    final cage = <List<Cell>>[
      [for (var x = centerX - 4; x <= centerX + 1; x++) Cell(x, centerY - 3)],
      [for (var y = centerY - 2; y <= centerY + 1; y++) Cell(centerX + 2, y)],
      [for (var x = centerX + 1; x >= centerX - 2; x--) Cell(x, centerY + 3)],
      [for (var y = centerY + 2; y >= centerY - 1; y--) Cell(centerX - 4, y)],
      [Cell(centerX + 2, centerY - 3), Cell(centerX + 3, centerY - 3)],
      [Cell(centerX + 2, centerY + 2), Cell(centerX + 2, centerY + 3)],
    ];
    final allPaths = [...cage, for (final path in orientedPaths) path.cells];
    return Puzzle(
      level,
      boardWidth,
      boardHeight,
      [
        for (var id = 0; id < allPaths.length; id++)
          ArrowPath(id, allPaths[id]),
      ],
      rescueCageIds: const {0, 1, 2, 3},
    );
  }

  static Puzzle _rescueOpeningMaze(int level) {
    const width = 24, height = 35;

    // Each list traces one arrow from tail to head. Only turns and endpoints
    // are stored. The final four routes frame the animal's pocket.
    const routes = <List<(int, int)>>[
      [(1, 32), (1, 33), (5, 33), (5, 32), (8, 32), (8, 33), (13, 33), (13, 32), (17, 32), (17, 33), (23, 33)],
      [(22, 31), (19, 31), (19, 30), (14, 30), (14, 31), (10, 31), (10, 30), (4, 30), (4, 31), (0, 31)],
      [(3, 34), (20, 34)],
      [(22, 5), (21, 5), (21, 1), (20, 1), (20, 6), (23, 6)],
      [(16, 3), (17, 3), (17, 6), (19, 6), (19, 2), (13, 2), (13, 0)],
      [(23, 22), (23, 29), (22, 29), (22, 27), (20, 27), (20, 30), (23, 30)],
      [(7, 7), (7, 6), (5, 6), (5, 9), (8, 9), (8, 6), (16, 6)],
      [(18, 16), (18, 14), (19, 14), (19, 19), (17, 19), (17, 13), (20, 13), (20, 7)],
      [(7, 27), (12, 27), (12, 24), (17, 24), (17, 22), (20, 22), (20, 14)],
      [(10, 29), (8, 29), (8, 28), (11, 28), (11, 30), (13, 30)],
      [(0, 3), (6, 3), (6, 0), (4, 0)],
      [(15, 3), (15, 4), (16, 4), (16, 5), (14, 5), (14, 3), (7, 3)],
      [(20, 26), (22, 26), (22, 24), (19, 24), (19, 28), (18, 28), (18, 23), (22, 23)],
      [(7, 26), (6, 26), (6, 28), (7, 28), (7, 29), (5, 29), (5, 25), (0, 25)],
      [(4, 27), (4, 26), (0, 26), (0, 27), (1, 27), (1, 30)],
      [(2, 7), (0, 7), (0, 4), (2, 4), (2, 6), (4, 6), (4, 10), (0, 10)],
      [(8, 1), (9, 1), (9, 0), (7, 0), (7, 2), (10, 2), (10, 0)],
      [(21, 7), (23, 7), (23, 8), (21, 8), (21, 11), (23, 11)],
      [(9, 26), (8, 26), (8, 25), (6, 25), (6, 21), (4, 21), (4, 11), (0, 11)],
      [(18, 12), (19, 12), (19, 7), (14, 7), (14, 11), (7, 11), (7, 10), (5, 10)],
      [(8, 24), (7, 24), (7, 23), (11, 23), (11, 25), (9, 25)],
      [(23, 16), (23, 13), (22, 13), (22, 22), (21, 22), (21, 12), (23, 12)],
      [(3, 17), (3, 12), (0, 12)],
      [(0, 15), (0, 13)],
      [(3, 18), (0, 18)],
      [(5, 22), (0, 22), (0, 19)],
      [(19, 29), (17, 29), (17, 25), (13, 25), (13, 29)],
      [(4, 28), (4, 29), (3, 29), (3, 27), (2, 27), (2, 30), (3, 30)],
      [(8, 5), (3, 5), (3, 4), (9, 4), (9, 5), (13, 5), (13, 4)],
      [(10, 8), (12, 8), (12, 9), (9, 9), (9, 7), (13, 7), (13, 10), (8, 10)],
      [(5, 12), (5, 20), (6, 20), (6, 11), (5, 11)],
      [(15, 28), (15, 27), (16, 27), (16, 29), (14, 29), (14, 26), (16, 26)],
      [(16, 9), (17, 9), (17, 10), (15, 10), (15, 8), (18, 8), (18, 11), (15, 11)],
      [(1, 21), (3, 21), (3, 19), (1, 19), (1, 20), (2, 20)],
      [(2, 14), (2, 17), (0, 17), (0, 16), (1, 16), (1, 13), (2, 13)],
      [(19, 1), (14, 1), (14, 0), (19, 0)],
      [(0, 2), (5, 2), (5, 1), (2, 1)],
      [(5, 23), (5, 24), (0, 24), (0, 23), (4, 23)],
      [(11, 1), (11, 2), (12, 2), (12, 0), (11, 0)],
      [(2, 8), (0, 8), (0, 9), (3, 9), (3, 7)],
      [(12, 32), (9, 32), (9, 31), (5, 31)],
      [(23, 31), (23, 32), (18, 32), (18, 31), (15, 31)],
      [(18, 20), (17, 20), (17, 21), (19, 21), (19, 20)],
      [(22, 3), (22, 4), (23, 4), (23, 2), (22, 2)],
      [(23, 10), (23, 9), (22, 9), (22, 10)],
      [(12, 23), (16, 23)],
      [(23, 17), (23, 21)],
      [(0, 28), (0, 30)],
      [(6, 7), (6, 8), (7, 8)],
      [(0, 32), (0, 33)],
      [(14, 33), (16, 33)],
      [(18, 5), (18, 3)],
      [(10, 4), (12, 4)],
      [(2, 32), (4, 32)],
      [(18, 17), (18, 18)],
      [(9, 24), (10, 24)],
      [(8, 12), (15, 12)],
      [(16, 12), (16, 22)],
      [(15, 22), (8, 22)],
      [(7, 21), (7, 12)],
    ];
    final paths = <ArrowPath>[];
    for (final route in routes) {
      final (startX, startY) = route.first;
      var current = Cell(startX, startY);
      final cells = [current];
      for (final (x, y) in route.skip(1)) {
        final target = Cell(x, y);
        final step = Cell((x - current.x).sign, (y - current.y).sign);
        while (current != target) {
          current += step;
          cells.add(current);
        }
      }
      paths.add(ArrowPath(paths.length, cells));
    }
    return Puzzle(
      level,
      width,
      height,
      paths,
      rescueCageIds: {for (var id = paths.length - 4; id < paths.length; id++) id},
    );
  }
  // Disjoint bent tiles create short acyclic removal chains.
  static Puzzle _circuit(int level) {
    final count = arrowCount(level);
    final columns = level <= 5
        ? 2
        : level <= 10
        ? 3
        : level <= 20
        ? 4
        : 5;
    final rows = (count / columns).ceil();
    final width = columns * 6 + 1, height = rows * 5 + 1;
    final random = Random(19391 + level * 137);
    final arrows = <ArrowPath>[];
    for (var row = 0; row < rows; row++) {
      final flip = (row + level).isOdd;
      for (var col = 0; col < columns && arrows.length < count; col++) {
        final x = 1 + col * 6, y = 1 + row * 5;
        final variant = random.nextInt(2);
        final cells = <Cell>[
          if (level > 10 && variant == 1) ...[
            Cell(x + 1, y + 3),
            Cell(x, y + 3),
          ],
          Cell(x, variant == 0 ? y : y + 2),
          Cell(x, y + 1),
          Cell(x + 1, y + 1),
          Cell(x + 2, y + 1),
          Cell(x + 2, y),
          Cell(x + 3, y),
        ];
        arrows.add(
          ArrowPath(
            arrows.length,
            cells.map((c) {
              final a = flip ? Cell(width - 1 - c.x, c.y) : c;
              return level.isEven ? Cell(a.y, width - 1 - a.x) : a;
            }).toList(),
          ),
        );
      }
    }
    return Puzzle(
      level,
      level.isEven ? height : width,
      level.isEven ? width : height,
      arrows,
    );
  }

  static Puzzle _legacyRescueOpeningMaze(int level) {
    const width = 22;
    const height = 32;
    final paths = <ArrowPath>[];

    // Long, alternating multi-turn routes fill the top and bottom of the
    // board. Their heads reach the outside edge, like the supplied reference.
    for (var band = 0; band < 3; band++) {
      final y = band * 3;
      if (band.isEven) {
        paths.add(
          ArrowPath(paths.length, [
            Cell(0, y),
            for (var x = 1; x <= width - 2; x++) Cell(x, y),
            Cell(width - 2, y + 1),
            for (var x = width - 3; x >= 1; x--) Cell(x, y + 1),
            Cell(1, y + 2),
            for (var x = 2; x < width; x++) Cell(x, y + 2),
          ]),
        );
      } else {
        paths.add(
          ArrowPath(paths.length, [
            Cell(width - 1, y),
            for (var x = width - 2; x >= 0; x--) Cell(x, y),
            Cell(0, y + 1),
            for (var x = 1; x <= width - 2; x++) Cell(x, y + 1),
            Cell(width - 2, y + 2),
            for (var x = width - 3; x >= 0; x--) Cell(x, y + 2),
          ]),
        );
      }
    }
    paths.add(
      ArrowPath(paths.length, [
        for (var x = width - 1; x >= 0; x--) Cell(x, 9),
      ]),
    );
    for (var band = 0; band < 3; band++) {
      final y = 22 + band * 3;
      if (band.isEven) {
        paths.add(
          ArrowPath(paths.length, [
            Cell(0, y),
            for (var x = 1; x <= width - 2; x++) Cell(x, y),
            Cell(width - 2, y + 1),
            for (var x = width - 3; x >= 1; x--) Cell(x, y + 1),
            Cell(1, y + 2),
            for (var x = 2; x < width; x++) Cell(x, y + 2),
          ]),
        );
      } else {
        paths.add(
          ArrowPath(paths.length, [
            Cell(width - 1, y),
            for (var x = width - 2; x >= 0; x--) Cell(x, y),
            Cell(0, y + 1),
            for (var x = 1; x <= width - 2; x++) Cell(x, y + 1),
            Cell(width - 2, y + 2),
            for (var x = width - 3; x >= 0; x--) Cell(x, y + 2),
          ]),
        );
      }
    }
    paths.add(
      ArrowPath(paths.length, [for (var x = 0; x < width; x++) Cell(x, 31)]),
    );

    const sideColumns = [0, 2, 4, 17, 19, 21];
    for (final x in sideColumns) {
      paths.add(
        ArrowPath(paths.length, [for (var y = 15; y >= 10; y--) Cell(x, y)]),
      );
      paths.add(
        ArrowPath(paths.length, [for (var y = 16; y <= 21; y++) Cell(x, y)]),
      );
    }

    final cageStart = paths.length;
    paths.addAll([
      ArrowPath(cageStart, [for (var x = 7; x <= 14; x++) Cell(x, 12)]),
      ArrowPath(cageStart + 1, [for (var y = 12; y <= 20; y++) Cell(15, y)]),
      ArrowPath(cageStart + 2, [for (var x = 14; x >= 7; x--) Cell(x, 20)]),
      ArrowPath(cageStart + 3, [for (var y = 19; y >= 12; y--) Cell(6, y)]),
    ]);
    return Puzzle(
      level,
      width,
      height,
      paths,
      rescueCageIds: {cageStart, cageStart + 1, cageStart + 2, cageStart + 3},
    );
  }

  static Puzzle _packedRescueMaze(int level) {
    final tier = min(6, (level - 2) ~/ 12);
    final width = 24 + tier;
    final height = 35 + tier * 2;
    final left = width ~/ 2 - 5, right = left + 9;
    final top = height ~/ 2 - 5, bottom = top + 10;
    final cage = [
      [for (var x = left + 1; x < right; x++) Cell(x, top)],
      [for (var y = top; y <= bottom; y++) Cell(right, y)],
      [for (var x = right - 1; x > left; x--) Cell(x, bottom)],
      [for (var y = bottom - 1; y >= top; y--) Cell(left, y)],
    ];
    final cageCells = cage.expand((path) => path).toSet();
    final free = <Cell>{
      for (var y = 0; y < height; y++)
        for (var x = 0; x < width; x++)
          if ((x < left || x > right || y < top || y > bottom) &&
              !(min(y, height - 1 - y) + min(x, width - 1 - x) < 3))
            Cell(x, y),
    };
    final random = Random(87171 + 24593 * level);
    final arrows = <ArrowPath>[];
    while (free.length > 1) {
      final rowMin = List.filled(height, width);
      final rowMax = List.filled(height, -1);
      final colMin = List.filled(width, height);
      final colMax = List.filled(width, -1);
      // The cage remains occupied during peeling. Every selected head can
      // exit through the edge once earlier picks have been removed.
      for (final cell in [...free, ...cageCells]) {
        final Cell(:x, :y) = cell;
        rowMin[y] = min(rowMin[y], x);
        rowMax[y] = max(rowMax[y], x);
        colMin[x] = min(colMin[x], y);
        colMax[x] = max(colMax[x], y);
      }
      final heads = <(Cell, Cell)>[
        for (var y = 0; y < height; y++) ...[
          (Cell(rowMin[y], y), const Cell(-1, 0)),
          (Cell(rowMax[y], y), const Cell(1, 0)),
        ],
        for (var x = 0; x < width; x++) ...[
          (Cell(x, colMin[x]), const Cell(0, -1)),
          (Cell(x, colMax[x]), const Cell(0, 1)),
        ],
      ]..removeWhere(
        (exit) => !free.contains(exit.$1) || !free.contains(exit.$1 - exit.$2),
      );
      if (heads.isEmpty) break;
      heads.shuffle(random);
      final length = arrows.length % 5 == 0
          ? 22 + random.nextInt(10)
          : 9 + random.nextInt(10);
      List<Cell>? best;
      var bestScore = -double.infinity;
      for (final (head, direction) in heads.take(30)) {
        final path = [head, head - direction];
        final used = path.toSet();
        var heading = path.last - head;
        var straight = 1;
        var turns = 0;
        while (path.length < length) {
          final options = _directions
              .where((d) => free.contains(path.last + d) && !used.contains(path.last + d))
              .toList();
          if (options.isEmpty) break;
          final next = options.contains(heading) &&
                  (straight < 2 || random.nextDouble() < .75)
              ? heading
              : options[random.nextInt(options.length)];
          if (next != heading) {
            turns++;
            straight = 0;
          }
          heading = next;
          straight++;
          final cell = path.last + heading;
          used.add(cell);
          path.add(cell);
        }
        final exit = head + direction;
        final interior = exit.x >= 0 && exit.x < width && exit.y >= 0 && exit.y < height;
        final score = path.length + min(turns, 5) * 1.1 +
            (interior ? 1.5 + tier * .35 : 0) + random.nextDouble();
        if (score > bestScore) {
          bestScore = score;
          best = path;
        }
      }
      final path = best!;
      free.removeAll(path);
      arrows.add(ArrowPath(arrows.length, path.reversed.toList()));
    }
    final cageStart = arrows.length;
    for (final route in cage) {
      arrows.add(ArrowPath(arrows.length, route));
    }
    return Puzzle(
      level,
      width,
      height,
      arrows,
      rescueCageIds: {for (var i = cageStart; i < arrows.length; i++) i},
    );
  }

  static Puzzle _generate(
    int level, {
    bool legacy = false,
    bool endless = false,
    bool rescue = false,
  }) {
    if (rescue) return _gentle(level, endless: true, rescue: true);
    if (endless) return _gentle(level, endless: true);
    // Keep the first five rounds as small, readable tutorials. From round 6
    // onward, switch to compact silhouette boards with bends and real blockers.
    if (level <= 5 && !legacy) return _circuit(level);
    final earlyCircuit = level <= 30 && !legacy;
    final hard = level % 10 == 0;
    final random = Random(7429 + level * 101);
    final target = earlyCircuit
        ? arrowCount(level)
        : 30 + (level.clamp(1, 800) - 1) * 170 ~/ 799;
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
        if (hard) {
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
              (mask.contains(head + direction) ? (hard ? 2.0 : .5) : 0) -
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
      final longThreshold = earlyCircuit ? max(8, (target * .5).ceil()) : 18;
      final long = arrows.where((a) => a.cells.length >= longThreshold).length;
      final blocked =
          arrows.where((a) => !candidate.canExit(a.id, {})).length / target;
      final depth = candidate.dependencyDepth;
      final minLongCount = earlyCircuit ? max(1, (target * .1).ceil()) : 2;
      final minLongest = earlyCircuit ? max(10, (target * .5).ceil()) : 24;
      final minBlocked = earlyCircuit ? .2 : (hard ? .7 : .4);
      if (coverage < (earlyCircuit ? .68 : .80) ||
          short < (target * (earlyCircuit ? .08 : .12)).floor() ||
          long < minLongCount ||
          !arrows.any((a) => a.cells.length >= minLongest) ||
          blocked < minBlocked ||
          (hard && depth < (earlyCircuit ? min(4, target ~/ 3) : 8))) {
        continue;
      }
      final score =
          (hard ? depth * 1.5 : 0) +
          coverage * 100 +
          min(short, target * .2) +
          min(long, target * .12) * 2 +
          blocked * (hard ? 20 : 4);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
      if (coverage >= .87 &&
          short >= target * (earlyCircuit ? .08 : .15) &&
          long >= (earlyCircuit ? minLongCount : max(2, target * .08)) &&
          blocked >= (earlyCircuit ? .2 : (hard ? .75 : .4))) {
        break;
      }
    }
    if (best == null) {
      if (earlyCircuit) return _circuit(level);
      throw StateError('Could not build level $level');
    }
    return best;
  }
}

class EndlessCatalog {
  static final Map<int, Puzzle> _cache = {};
  static int arrowCount(int round) => (10 + (round - 1) ~/ 2).clamp(10, 80);
  static Puzzle get(int round) {
    if (round < 1) throw RangeError.value(round, 'round');
    if (_cache.containsKey(round)) return _cache[round]!;
    if (_cache.length >= 24) _cache.remove(_cache.keys.first);
    return _cache[round] = LevelCatalog._generate(round, endless: true);
  }
}

class RescueCatalog {
  static const count = 3000;
  static final Map<int, Puzzle> _cache = {};
  static const animals = ['🦜', '🐦', '🐰', '🦊', '🐢', '🦔'];
  static String animal(int round) => animals[(round - 1) % animals.length];
  static Puzzle get(int round) {
    if (round < 1 || round > count) throw RangeError.range(round, 1, count);
    if (_cache.containsKey(round)) return _cache[round]!;
    if (_cache.length >= 24) _cache.remove(_cache.keys.first);
    return _cache[round] = round == 1
        ? LevelCatalog._rescueOpeningMaze(round)
        : LevelCatalog._packedRescueMaze(round);
  }

  static Puzzle resume(int round, Map<String, dynamic>? run) {
    final current = get(round);
    if (run == null || run['layout'] == GameSession(current).layoutKey) {
      return current;
    }
    final previous = LevelCatalog._generate(round, rescue: true);
    return run['layout'] == GameSession(previous).layoutKey ? previous : current;
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
