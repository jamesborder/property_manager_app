import 'package:hsoa_opoly/models/color_group.dart';
import 'package:hsoa_opoly/models/property.dart';

/// Test fixtures for creating property sets in various states.
///
/// These helpers make tests readable by abstracting away the boilerplate
/// of creating properties with specific configurations.

// ─────────────────────────────────────────────────────────────────────────────
// STREET PROPERTIES
// ─────────────────────────────────────────────────────────────────────────────

/// Creates Mediterranean Avenue (Brown, $60)
Property mediterranean({
  bool isOwned = false,
  int houseCount = 0,
  bool isMortgaged = false,
}) {
  return Property(
    id: 'mediterranean',
    name: 'Mediterranean Avenue',
    colorGroup: ColorGroup.brown,
    purchasePrice: 60,
    rentTiers: [2, 10, 30, 90, 160, 250],
    isOwned: isOwned,
    houseCount: houseCount,
    isMortgaged: isMortgaged,
  );
}

/// Creates Baltic Avenue (Brown, $60)
Property baltic({
  bool isOwned = false,
  int houseCount = 0,
  bool isMortgaged = false,
}) {
  return Property(
    id: 'baltic',
    name: 'Baltic Avenue',
    colorGroup: ColorGroup.brown,
    purchasePrice: 60,
    rentTiers: [4, 20, 60, 180, 320, 450],
    isOwned: isOwned,
    houseCount: houseCount,
    isMortgaged: isMortgaged,
  );
}

/// Creates Boardwalk (Dark Blue, $400)
Property boardwalk({
  bool isOwned = false,
  int houseCount = 0,
  bool isMortgaged = false,
}) {
  return Property(
    id: 'boardwalk',
    name: 'Boardwalk',
    colorGroup: ColorGroup.darkBlue,
    purchasePrice: 400,
    rentTiers: [50, 200, 600, 1400, 1700, 2000],
    isOwned: isOwned,
    houseCount: houseCount,
    isMortgaged: isMortgaged,
  );
}

/// Creates Park Place (Dark Blue, $350)
Property parkPlace({
  bool isOwned = false,
  int houseCount = 0,
  bool isMortgaged = false,
}) {
  return Property(
    id: 'parkplace',
    name: 'Park Place',
    colorGroup: ColorGroup.darkBlue,
    purchasePrice: 350,
    rentTiers: [35, 175, 500, 1100, 1300, 1500],
    isOwned: isOwned,
    houseCount: houseCount,
    isMortgaged: isMortgaged,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RAILROADS
// ─────────────────────────────────────────────────────────────────────────────

/// Creates Reading Railroad
Property readingRailroad({
  bool isOwned = false,
  bool isMortgaged = false,
}) {
  return Property(
    id: 'reading',
    name: 'Reading Railroad',
    colorGroup: ColorGroup.railroad,
    purchasePrice: 200,
    rentTiers: [25, 50, 100, 200],
    isOwned: isOwned,
    isMortgaged: isMortgaged,
  );
}

/// Creates Pennsylvania Railroad
Property pennsylvaniaRailroad({
  bool isOwned = false,
  bool isMortgaged = false,
}) {
  return Property(
    id: 'pennsylvania_rr',
    name: 'Pennsylvania Railroad',
    colorGroup: ColorGroup.railroad,
    purchasePrice: 200,
    rentTiers: [25, 50, 100, 200],
    isOwned: isOwned,
    isMortgaged: isMortgaged,
  );
}

/// Creates B&O Railroad
Property boRailroad({
  bool isOwned = false,
  bool isMortgaged = false,
}) {
  return Property(
    id: 'bo',
    name: 'B. & O. Railroad',
    colorGroup: ColorGroup.railroad,
    purchasePrice: 200,
    rentTiers: [25, 50, 100, 200],
    isOwned: isOwned,
    isMortgaged: isMortgaged,
  );
}

/// Creates Short Line Railroad
Property shortLineRailroad({
  bool isOwned = false,
  bool isMortgaged = false,
}) {
  return Property(
    id: 'shortline',
    name: 'Short Line',
    colorGroup: ColorGroup.railroad,
    purchasePrice: 200,
    rentTiers: [25, 50, 100, 200],
    isOwned: isOwned,
    isMortgaged: isMortgaged,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// UTILITIES
// ─────────────────────────────────────────────────────────────────────────────

/// Creates Electric Company
Property electricCompany({
  bool isOwned = false,
  bool isMortgaged = false,
}) {
  return Property(
    id: 'electric',
    name: 'Electric Company',
    colorGroup: ColorGroup.utility,
    purchasePrice: 150,
    rentTiers: [],
    isOwned: isOwned,
    isMortgaged: isMortgaged,
  );
}

/// Creates Water Works
Property waterWorks({
  bool isOwned = false,
  bool isMortgaged = false,
}) {
  return Property(
    id: 'water',
    name: 'Water Works',
    colorGroup: ColorGroup.utility,
    purchasePrice: 150,
    rentTiers: [],
    isOwned: isOwned,
    isMortgaged: isMortgaged,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PROPERTY SET BUILDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Creates a minimal property set with just the brown color group (2 properties)
List<Property> brownColorGroup({
  bool mediterraneanOwned = false,
  bool balticOwned = false,
  int mediterraneanHouses = 0,
  int balticHouses = 0,
  bool mediterraneanMortgaged = false,
  bool balticMortgaged = false,
}) {
  return [
    mediterranean(
      isOwned: mediterraneanOwned,
      houseCount: mediterraneanHouses,
      isMortgaged: mediterraneanMortgaged,
    ),
    baltic(
      isOwned: balticOwned,
      houseCount: balticHouses,
      isMortgaged: balticMortgaged,
    ),
  ];
}

/// Creates a minimal property set with just the dark blue color group (2 properties)
List<Property> darkBlueColorGroup({
  bool parkPlaceOwned = false,
  bool boardwalkOwned = false,
  int parkPlaceHouses = 0,
  int boardwalkHouses = 0,
  bool parkPlaceMortgaged = false,
  bool boardwalkMortgaged = false,
}) {
  return [
    parkPlace(
      isOwned: parkPlaceOwned,
      houseCount: parkPlaceHouses,
      isMortgaged: parkPlaceMortgaged,
    ),
    boardwalk(
      isOwned: boardwalkOwned,
      houseCount: boardwalkHouses,
      isMortgaged: boardwalkMortgaged,
    ),
  ];
}

/// Creates all four railroads
List<Property> allRailroads({
  bool readingOwned = false,
  bool pennsylvaniaOwned = false,
  bool boOwned = false,
  bool shortLineOwned = false,
  bool readingMortgaged = false,
  bool pennsylvaniaMortgaged = false,
  bool boMortgaged = false,
  bool shortLineMortgaged = false,
}) {
  return [
    readingRailroad(isOwned: readingOwned, isMortgaged: readingMortgaged),
    pennsylvaniaRailroad(isOwned: pennsylvaniaOwned, isMortgaged: pennsylvaniaMortgaged),
    boRailroad(isOwned: boOwned, isMortgaged: boMortgaged),
    shortLineRailroad(isOwned: shortLineOwned, isMortgaged: shortLineMortgaged),
  ];
}

/// Creates both utilities
List<Property> bothUtilities({
  bool electricOwned = false,
  bool waterOwned = false,
  bool electricMortgaged = false,
  bool waterMortgaged = false,
}) {
  return [
    electricCompany(isOwned: electricOwned, isMortgaged: electricMortgaged),
    waterWorks(isOwned: waterOwned, isMortgaged: waterMortgaged),
  ];
}
