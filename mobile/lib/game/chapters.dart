import 'puzzle.dart';

class ChapterCatalog {
  static const size = 100;
  static const count = LevelCatalog.count ~/ size;
  static int of(int level) => (level - 1) ~/ size + 1;
  static int first(int chapter) => (chapter - 1) * size + 1;
  static int last(int chapter) => chapter * size;
  static String name(int chapter) {
    const names = [
      'Beginner Bay',
      'Sapphire Grove',
      'Crystal Canyon',
      'Pro Peaks',
      'Aurora Garden',
      'Moonlit Ruins',
      'Royal Summit',
      'Master Realm',
      'Celestial Isles',
      'Nova Legends',
    ];
    final cycle = (chapter - 1) ~/ names.length;
    return '${names[(chapter - 1) % names.length]}${cycle == 0 ? '' : ' · ${cycle + 1}'}';
  }
}
