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
  });
  final String id, name, description;
  final int cost, unlock;
  final String category;
  final String? asset;
  final bool premium;
  final double scale;
}

const gardenSlotCount = 12;
const gardenPremiumAds = 3;

class GardenPosition {
  const GardenPosition(this.x, this.y);
  final double x, y;
}

const gardenItems = [
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
    'A blue-and-gold sofa for your garden retreat.',
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
];
