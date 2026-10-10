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
    'Blue hydrangeas',
    120,
    50,
    'Blue blossoms for a brighter corner.',
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
];
