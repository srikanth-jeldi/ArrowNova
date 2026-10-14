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
  });
  final String id, name, description;
  final int cost, unlock;
  final String category;
  final String? asset;
  final bool premium;
  final double scale;
  final bool homeOnly, wall;
  bool get indoors =>
      homeOnly || asset != null || id == 'lantern' || id == 'flowers';
}

const gardenSlotCount = 12;
const gardenPremiumAds = 3;

class GardenPosition {
  const GardenPosition(this.x, this.y);
  final double x, y;
}

const gardenItems = [
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
];
