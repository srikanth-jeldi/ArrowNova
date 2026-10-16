// The catalogue uses original, photographed-style 2D sprites, not colour swaps.
const decorCategories = [
  'Sofas',
  'Pillows',
  'Carpets',
  'Curtains',
  'Flower vases',
  'Photo frames',
  'Lights',
];
const decorCollections = [
  'Everyday linen',
  'Emerald elegance',
  'Rose atelier',
  'Coastal blue',
];
const decorRoomNames = [
  'Warm oak lounge',
  'Blush pink retreat',
  'Soft blue haven',
];
const decorRoomBriefs = [
  'Warm oak + ivory. Try emerald or blue for a richer contrast.',
  'Blush pink + ivory or rose. Try emerald for a bold contrast.',
  'Soft blue + ivory or blue. Try blush for a warm contrast.',
];
String decorStyleHint(int level, int collection) {
  final room = (level - 1) % 3;
  if (collection == 0) return 'Neutral match';
  if (room == 1 && collection == 2 || room == 2 && collection == 3) {
    return 'Matching palette';
  }
  if (room == 1 && collection == 1 ||
      room == 2 && collection == 2 ||
      room == 0 && (collection == 1 || collection == 3)) {
    return 'Suggested contrast';
  }
  return 'Creative accent';
}

const decorAdsRequired = 3;

class DecorPiece {
  const DecorPiece(this.categoryIndex, this.collection);
  final int categoryIndex, collection;
  String get id => 'decor_${categoryIndex}_$collection';
  String get category => decorCategories[categoryIndex];
  bool get premium => collection != 0;
  String get name => const [
    ['Linen haven', 'Emerald velvet', 'Rose curved sofa', 'Coastal blue sofa'],
    ['Woven ivory', 'Botanical silk', 'Blush boucle', 'Indigo woven pillow'],
    [
      'Natural weave',
      'Heritage emerald',
      'Rose medallion',
      'Coastal woven rug',
    ],
    ['Airy linen', 'Velvet emerald', 'Soft blush drapes', 'Blue linen drapes'],
    [
      'Eucalyptus ceramic',
      'Golden orchid',
      'Peony porcelain',
      'Blue hydrangea vase',
    ],
    ['Quiet landscape', 'Gilded botanicals', 'Rose gallery', 'Coastal horizon'],
    [
      'Oak tripod',
      'Brass arc lamp',
      'Sculpted marble lamp',
      'Blue ceramic lamp',
    ],
  ][categoryIndex][collection];
  String get atlas => 'assets/art/decor/collection_$collection.webp';
}

final decorPieces = [
  for (var c = 0; c < decorCategories.length; c++)
    for (var style = 0; style < decorCollections.length; style++)
      DecorPiece(c, style),
];
DecorPiece? decorPiece(String id) {
  for (final item in decorPieces) {
    if (item.id == id) return item;
  }
  return null;
}

class DecorRoom {
  DecorRoom({
    Map<String, String>? placed,
    Map<String, int>? credits,
    this.finished = false,
  }) : placed = placed ?? {},
       credits = credits ?? {};
  final Map<String, String> placed;
  final Map<String, int> credits;
  bool finished;
  int adsFor(DecorPiece item) => credits[item.id] ?? 0;
  bool owns(DecorPiece item) =>
      !item.premium || adsFor(item) >= decorAdsRequired;
  bool get complete => decorCategories.every(placed.containsKey);
  bool place(DecorPiece item) {
    if (finished || !owns(item)) return false;
    placed[item.category] = item.id;
    return true;
  }

  bool remove(String category) {
    if (finished) return false;
    return placed.remove(category) != null;
  }

  bool reward(DecorPiece item) {
    if (finished || !item.premium || owns(item)) return false;
    credits[item.id] = adsFor(item) + 1;
    return true;
  }

  Map<String, Object> toJson() => {
    'placed': placed,
    'credits': credits,
    'finished': finished,
  };
  factory DecorRoom.fromJson(Object? raw) {
    final data = raw is Map ? raw : const {};
    final room = DecorRoom();
    final creditData = data['credits'];
    if (creditData is Map) {
      for (final e in creditData.entries) {
        final item = decorPiece('${e.key}');
        if (item != null && item.premium && e.value is int) {
          room.credits[item.id] = (e.value as int).clamp(0, decorAdsRequired);
        }
      }
    }
    final placedData = data['placed'];
    if (placedData is Map) {
      for (final e in placedData.entries) {
        final item = decorPiece('${e.value}');
        if (item != null && item.category == e.key && room.owns(item)) {
          room.place(item);
        }
      }
    }
    room.finished = data['finished'] == true && room.complete;
    return room;
  }
}

class HomeDecorProgress {
  HomeDecorProgress({this.level = 1, Map<int, DecorRoom>? rooms})
    : rooms = rooms ?? {};
  int level;
  final Map<int, DecorRoom> rooms;
  DecorRoom get current => rooms.putIfAbsent(level, DecorRoom.new);
  bool finish() {
    if (!current.complete || current.finished) return false;
    current.finished = true;
    return true;
  }

  bool next() {
    if (!current.finished) return false;
    level++;
    return true;
  }

  Map<String, Object> toJson() => {
    'level': level,
    'rooms': rooms.map((key, value) => MapEntry('$key', value.toJson())),
  };
  factory HomeDecorProgress.fromJson(Object? raw) {
    final data = raw is Map ? raw : const {};
    final result = HomeDecorProgress();
    if (data['level'] is int && (data['level'] as int) > 0) {
      result.level = data['level'] as int;
    }
    if (data['rooms'] is Map) {
      for (final e in (data['rooms'] as Map).entries) {
        final n = int.tryParse('${e.key}');
        if (n != null && n > 0 && n <= result.level) {
          result.rooms[n] = DecorRoom.fromJson(e.value);
        }
      }
    }
    return result;
  }
}
