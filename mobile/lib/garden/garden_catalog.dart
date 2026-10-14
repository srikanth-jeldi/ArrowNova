class GardenItem {
  const GardenItem(
    this.id,
    this.name,
    this.cost,
    this.unlock,
    this.description, {
    this.category = 'Landmarks',
    this.asset,
    this.premium = false,
    this.scale = .20,
    this.homeOnly = false,
    this.wall = false,
    this.model,
    this.tint,
  });
  final String id, name, description;
  final int cost, unlock;
  final String category;
  final String? asset;
  final bool premium;
  final double scale;
  final bool homeOnly, wall;
  final String? model;
  final int? tint;
  bool get indoors =>
      homeOnly || asset != null || id == 'lantern' || id == 'flowers';
}

const gardenSlotCount = 12;
const gardenPremiumAds = 3;

class GardenPosition {
  const GardenPosition(this.x, this.y);
  final double x, y;
}

const _baseGardenItems = [
  // Keep the original six atlas-backed items first.
  GardenItem('lantern', 'First light', 0, 0, 'A warm welcome to your garden.'),
  GardenItem(
    'flowers',
    'Blue hydrangeas',
    120,
    50,
    'Blue blossoms for a brighter corner.',
    category: 'Flowers',
  ),
  GardenItem(
    'fountain',
    'Stone fountain',
    300,
    50,
    'A little pool of quiet light.',
  ),
  GardenItem(
    'tree',
    'Japanese maple',
    450,
    100,
    'A living canopy of fresh green leaves.',
  ),
  GardenItem(
    'arch',
    'Rose arch',
    600,
    150,
    'An entrance worthy of your journey.',
  ),
  GardenItem(
    'obelisk',
    'Garden sundial',
    800,
    200,
    'A monument to small victories.',
  ),
  GardenItem(
    'roses',
    'Blush roses',
    40,
    3,
    'Pink roses in a warm terracotta pot.',
    category: 'Flowers',
    asset: 'assets/art/garden/roses.webp',
  ),
  GardenItem(
    'lavender',
    'Lavender dreams',
    60,
    5,
    'A little colour for a quiet corner.',
    category: 'Flowers',
    asset: 'assets/art/garden/lavender.webp',
  ),
  GardenItem(
    'jar',
    'Jade garden jar',
    90,
    8,
    'Turquoise glaze with golden leaves.',
    category: 'Pots & jars',
    asset: 'assets/art/garden/jar.webp',
  ),
  GardenItem(
    'chair',
    'Wicker armchair',
    140,
    12,
    'Make a comfortable place to unwind.',
    category: 'Furniture',
    asset: 'assets/art/garden/chair.webp',
    scale: .25,
  ),
  GardenItem(
    'sofa',
    'Sapphire lounge',
    0,
    0,
    'A blue-and-gold sofa for your favourite retreat.',
    category: 'Furniture',
    asset: 'assets/art/garden/sofa.webp',
    premium: true,
    scale: .34,
  ),
  GardenItem(
    'vase',
    'Royal lily vase',
    0,
    0,
    'White lilies in a sapphire glass vase.',
    category: 'Pots & jars',
    asset: 'assets/art/garden/vase.webp',
    premium: true,
  ),
  GardenItem(
    'curtains',
    'Velvet curtains',
    0,
    0,
    'Teal velvet and golden tiebacks for your window.',
    category: 'Curtains',
    premium: true,
    homeOnly: true,
    wall: true,
    scale: .47,
  ),
  GardenItem(
    'linen',
    'Linen curtains',
    30,
    1,
    'Soft ivory drapes welcome the morning light.',
    category: 'Curtains',
    homeOnly: true,
    wall: true,
    scale: .47,
  ),
  GardenItem(
    'rug',
    'Sapphire rug',
    50,
    3,
    'A woven blue rug with a golden border.',
    category: 'Rugs',
    homeOnly: true,
    scale: .44,
  ),
  GardenItem(
    'table',
    'Oak coffee table',
    80,
    5,
    'Warm wood for the heart of your living room.',
    category: 'Furniture',
    homeOnly: true,
    scale: .29,
  ),
  GardenItem(
    'lamp',
    'Golden floor lamp',
    70,
    4,
    'A soft glow for your reading corner.',
    category: 'Lighting',
    homeOnly: true,
    scale: .28,
  ),
  GardenItem(
    'painting',
    'Mountain sunrise',
    60,
    4,
    'A framed landscape for your wall.',
    category: 'Wall art',
    homeOnly: true,
    wall: true,
    scale: .23,
  ),
  GardenItem(
    'cream_sofa',
    'Everyday sofa',
    100,
    8,
    'A cosy cream sofa for your first room.',
    category: 'Furniture',
    homeOnly: true,
    scale: .34,
  ),
  GardenItem(
    'royal_rug',
    'Royal medallion carpet',
    0,
    0,
    'Golden embroidery and a rich jewel-blue centre.',
    category: 'Rugs',
    homeOnly: true,
    premium: true,
    scale: .48,
  ),
  GardenItem(
    'crystal_lamp',
    'Crystal floor lamp',
    0,
    0,
    'A sparkling crystal shade and polished gold stand.',
    category: 'Lighting',
    homeOnly: true,
    premium: true,
    scale: .28,
  ),
  GardenItem(
    'gallery',
    'Golden gallery',
    0,
    0,
    'Three framed landscapes for your feature wall.',
    category: 'Wall art',
    homeOnly: true,
    premium: true,
    wall: true,
    scale: .34,
  ),
  GardenItem(
    'bed',
    'Linen bed',
    110,
    8,
    'A cosy bed with soft linen and oak frame.',
    category: 'Beds',
    homeOnly: true,
    scale: .4,
  ),
  GardenItem(
    'royal_bed',
    'Royal upholstered bed',
    0,
    0,
    'Sapphire upholstery and a gold-accented throw.',
    category: 'Beds',
    homeOnly: true,
    premium: true,
    scale: .4,
  ),
];

// These are explicit colour/material choices, not hundreds of unique meshes.
const roomPalettes = <(String, int)>[
  ('Ivory', 0xFFE4D7BC),
  ('Sage', 0xFF91AC95),
  ('Ocean', 0xFF427C96),
  ('Rose', 0xFFCA8D9C),
  ('Sand', 0xFFBF9D78),
  ('Slate', 0xFF6D7D8A),
  ('Olive', 0xFF8C9867),
  ('Coral', 0xFFD18D76),
  ('Lavender', 0xFFAA9AC4),
  ('Terracotta', 0xFFB37356),
  ('Cloud', 0xFFDDE5E4),
  ('Charcoal', 0xFF535B65),
  ('Pearl', 0xFFE9DCC9),
  ('Bronze', 0xFFA98250),
  ('Midnight', 0xFF355576),
  ('Emerald', 0xFF387B69),
];
const _roomModels = <String, String>{
  'cream_sofa': 'sofa',
  'chair': 'armchair',
  'bed': 'bed',
  'linen': 'curtains',
  'rug': 'carpet',
  'table': 'coffee table',
  'lamp': 'floor lamp',
  'painting': 'wall art',
  'jar': 'vase',
  'roses': 'rose planter',
  'lavender': 'lavender planter',
  'vase': 'lily arrangement',
};
final gardenItems = <GardenItem>[
  ..._baseGardenItems,
  for (final entry in _roomModels.entries)
    for (var i = 0; i < roomPalettes.length; i++)
      GardenItem(
        'room_${entry.key}_$i',
        '${roomPalettes[i].$1} ${entry.value}',
        i >= 12 ? 0 : 40 + (i % 5) * 20,
        i >= 12 ? 0 : 1 + i % 8,
        i >= 12
            ? 'Premium finish with rich colours and decorative details.'
            : 'A coordinated colour choice for your room.',
        category: _baseGardenItems
            .firstWhere((item) => item.id == entry.key)
            .category,
        homeOnly: true,
        premium: i >= 12,
        wall: _baseGardenItems.firstWhere((item) => item.id == entry.key).wall,
        model: entry.key,
        tint: roomPalettes[i].$2,
      ),
];
