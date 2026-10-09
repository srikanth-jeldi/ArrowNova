class GardenItem {
  const GardenItem(
    this.id,
    this.name,
    this.cost,
    this.unlock,
    this.description,
  );
  final String id, name, description;
  final int cost, unlock;
}

const gardenItems = [
  GardenItem('lantern', 'First light', 0, 0, 'A warm welcome to your garden.'),
  GardenItem(
    'flowers',
    'Crystal blooms',
    120,
    50,
    'Blue blossoms for a brighter corner.',
  ),
  GardenItem(
    'fountain',
    'Moonlit fountain',
    300,
    50,
    'A little pool of quiet light.',
  ),
  GardenItem(
    'tree',
    'Sapphire sapling',
    450,
    100,
    'Your very own crystal tree.',
  ),
  GardenItem(
    'arch',
    'Golden arch',
    600,
    150,
    'An entrance worthy of your journey.',
  ),
  GardenItem(
    'obelisk',
    'Star monument',
    800,
    200,
    'A monument to small victories.',
  ),
];
