import '../models/color_group.dart';
import '../models/property.dart';

/// All 28 properties from Monopoly: 22 streets, 4 railroads, 2 utilities
/// Street rent tiers: [base, 1 house, 2 houses, 3 houses, 4 houses, hotel]
/// Railroad rent tiers: [1 owned, 2 owned, 3 owned, 4 owned]
/// Utility rent tiers: [] (4x or 10x dice roll)
List<Property> createInitialProperties() {
  return [
    // Brown
    Property(
      id: 'mediterranean',
      name: 'Mediterranean Avenue',
      colorGroup: ColorGroup.brown,
      purchasePrice: 60,
      rentTiers: [2, 10, 30, 90, 160, 250],
    ),
    Property(
      id: 'baltic',
      name: 'Baltic Avenue',
      colorGroup: ColorGroup.brown,
      purchasePrice: 60,
      rentTiers: [4, 20, 60, 180, 320, 450],
    ),

    /// Railroad
    Property(
      id: 'reading',
      name: 'Reading Railroad',
      colorGroup: ColorGroup.railroad,
      purchasePrice: 200,
      rentTiers: [25, 50, 100, 200],
    ),

    // Light Blue
    Property(
      id: 'oriental',
      name: 'Oriental Avenue',
      colorGroup: ColorGroup.lightBlue,
      purchasePrice: 100,
      rentTiers: [6, 30, 90, 270, 400, 550],
    ),
    Property(
      id: 'vermont',
      name: 'Vermont Avenue',
      colorGroup: ColorGroup.lightBlue,
      purchasePrice: 100,
      rentTiers: [6, 30, 90, 270, 400, 550],
    ),
    Property(
      id: 'connecticut',
      name: 'Connecticut Avenue',
      colorGroup: ColorGroup.lightBlue,
      purchasePrice: 120,
      rentTiers: [8, 40, 100, 300, 450, 600],
    ),

    // Pink
    Property(
      id: 'stcharles',
      name: 'St. Charles Place',
      colorGroup: ColorGroup.pink,
      purchasePrice: 140,
      rentTiers: [10, 50, 150, 450, 625, 750],
    ),

    /// Utility
    Property(
      id: 'electric',
      name: 'Electric Company',
      colorGroup: ColorGroup.utility,
      purchasePrice: 150,
      rentTiers: [], // 4x or 10x dice roll
    ),

    Property(
      id: 'states',
      name: 'States Avenue',
      colorGroup: ColorGroup.pink,
      purchasePrice: 140,
      rentTiers: [10, 50, 150, 450, 625, 750],
    ),
    Property(
      id: 'virginia',
      name: 'Virginia Avenue',
      colorGroup: ColorGroup.pink,
      purchasePrice: 160,
      rentTiers: [12, 60, 180, 500, 700, 900],
    ),

    /// RAILROAD
    Property(
      id: 'pennsylvania_rr',
      name: 'Pennsylvania Railroad',
      colorGroup: ColorGroup.railroad,
      purchasePrice: 200,
      rentTiers: [25, 50, 100, 200],
    ),

    // Orange
    Property(
      id: 'stjames',
      name: 'St. James Place',
      colorGroup: ColorGroup.orange,
      purchasePrice: 180,
      rentTiers: [14, 70, 200, 550, 750, 950],
    ),
    Property(
      id: 'tennessee',
      name: 'Tennessee Avenue',
      colorGroup: ColorGroup.orange,
      purchasePrice: 180,
      rentTiers: [14, 70, 200, 550, 750, 950],
    ),
    Property(
      id: 'newyork',
      name: 'New York Avenue',
      colorGroup: ColorGroup.orange,
      purchasePrice: 200,
      rentTiers: [16, 80, 220, 600, 800, 1000],
    ),

    // Red
    Property(
      id: 'kentucky',
      name: 'Kentucky Avenue',
      colorGroup: ColorGroup.red,
      purchasePrice: 220,
      rentTiers: [18, 90, 250, 700, 875, 1050],
    ),
    Property(
      id: 'indiana',
      name: 'Indiana Avenue',
      colorGroup: ColorGroup.red,
      purchasePrice: 220,
      rentTiers: [18, 90, 250, 700, 875, 1050],
    ),
    Property(
      id: 'illinois',
      name: 'Illinois Avenue',
      colorGroup: ColorGroup.red,
      purchasePrice: 240,
      rentTiers: [20, 100, 300, 750, 925, 1100],
    ),

    /// RAILROAD
    Property(
      id: 'bo',
      name: 'B. & O. Railroad',
      colorGroup: ColorGroup.railroad,
      purchasePrice: 200,
      rentTiers: [25, 50, 100, 200],
    ),

    // Yellow
    Property(
      id: 'atlantic',
      name: 'Atlantic Avenue',
      colorGroup: ColorGroup.yellow,
      purchasePrice: 260,
      rentTiers: [22, 110, 330, 800, 975, 1150],
    ),
    Property(
      id: 'ventnor',
      name: 'Ventnor Avenue',
      colorGroup: ColorGroup.yellow,
      purchasePrice: 260,
      rentTiers: [22, 110, 330, 800, 975, 1150],
    ),

    /// UTILITY
    Property(
      id: 'water',
      name: 'Water Works',
      colorGroup: ColorGroup.utility,
      purchasePrice: 150,
      rentTiers: [], // 4x or 10x dice roll
    ),

    Property(
      id: 'marvin',
      name: 'Marvin Gardens',
      colorGroup: ColorGroup.yellow,
      purchasePrice: 280,
      rentTiers: [24, 120, 360, 850, 1025, 1200],
    ),

    // Green
    Property(
      id: 'pacific',
      name: 'Pacific Avenue',
      colorGroup: ColorGroup.green,
      purchasePrice: 300,
      rentTiers: [26, 130, 390, 900, 1100, 1275],
    ),
    Property(
      id: 'northcarolina',
      name: 'North Carolina Avenue',
      colorGroup: ColorGroup.green,
      purchasePrice: 300,
      rentTiers: [26, 130, 390, 900, 1100, 1275],
    ),
    Property(
      id: 'pennsylvania',
      name: 'Pennsylvania Avenue',
      colorGroup: ColorGroup.green,
      purchasePrice: 320,
      rentTiers: [28, 150, 450, 1000, 1200, 1400],
    ),

    /// RAILROAD
    Property(
      id: 'shortline',
      name: 'Short Line',
      colorGroup: ColorGroup.railroad,
      purchasePrice: 200,
      rentTiers: [25, 50, 100, 200],
    ),

    // Dark Blue
    Property(
      id: 'parkplace',
      name: 'Park Place',
      colorGroup: ColorGroup.darkBlue,
      purchasePrice: 350,
      rentTiers: [35, 175, 500, 1100, 1300, 1500],
    ),
    Property(
      id: 'boardwalk',
      name: 'Boardwalk',
      colorGroup: ColorGroup.darkBlue,
      purchasePrice: 400,
      rentTiers: [50, 200, 600, 1400, 1700, 2000],
    ),

  ];
}
