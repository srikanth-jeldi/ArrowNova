import 'puzzle.dart';

String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class DailyCatalog {
  static Puzzle get(DateTime date) {
    final day =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final source = LevelCatalog.get(51 + (day * 37) % 250);
    // Deterministic rotations of curated-solvable geometry; independent of Classic progress.
    final turns = day % 4;
    Cell rotate(Cell cell) => switch (turns) {
      1 => Cell(source.height - 1 - cell.y, cell.x),
      2 => Cell(source.width - 1 - cell.x, source.height - 1 - cell.y),
      3 => Cell(cell.y, source.width - 1 - cell.x),
      _ => cell,
    };
    return Puzzle(
      source.level,
      turns.isOdd ? source.height : source.width,
      turns.isOdd ? source.width : source.height,
      [
        for (final a in source.arrows)
          ArrowPath(a.id, a.cells.map(rotate).toList()),
      ],
    );
  }
}
