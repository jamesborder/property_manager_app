import '../models/color_group.dart';
import '../models/property.dart';

/// Pure game logic — no state management, no Flutter imports.
/// Shared across Provider, Riverpod, and Bloc/Cubit versions.
class GameRules {

  GameRules._(); // Prevent instantiation

  // ─────────────────────────────────────────────────────────────────────────────
  // RENT CALCULATION
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get actual rent value for a property (streets, railroads).
  /// For utilities, returns the multiplier (caller handles dice roll).
  static int getActualRentValue(Property property, List<Property> allProperties) {
    if (property.isMortgaged) return 0;

    if (property.isRailroad) {
      return getRailroadRent(property, allProperties);
    }

    if (property.isUtility) {
      return getUtilityMultiplier(allProperties);
    }

    // Street property
    int baseRent = property.currentRent;
    if (property.houseCount == 0 && ownsFullColorGroup(property.colorGroup, allProperties)) {
      return baseRent * 2;
    }
    return baseRent;
  }

  /// Display string for rent (e.g. "$50" or "Dice roll x4")
  static String getRentDisplayString(Property property, List<Property> allProperties) {
    if (property.isMortgaged) return '\$0';

    if (property.isRailroad) {
      return '\$${getRailroadRent(property, allProperties)}';
    }

    if (property.isUtility) {
      return 'Dice roll x${getUtilityMultiplier(allProperties)}';
    }

    // Street property
    int baseRent = property.currentRent;
    if (property.houseCount == 0 && ownsFullColorGroup(property.colorGroup, allProperties)) {
      return '\$${baseRent * 2}';
    }
    return '\$$baseRent';
  }

  /// Railroad rent based on how many railroads are owned (not mortgaged)
  static int getRailroadRent(Property property, List<Property> allProperties) {
    if (!property.isRailroad || property.isMortgaged) return 0;
    final ownedCount = getOwnedRailroadCount(allProperties);
    if (ownedCount == 0) return 0;
    return property.rentTiers[ownedCount - 1];
  }

  /// Number of railroads owned and not mortgaged
  static int getOwnedRailroadCount(List<Property> allProperties) {
    return allProperties
        .where((p) => p.isRailroad && p.isOwned && !p.isMortgaged)
        .length;
  }

  /// Number of utilities owned and not mortgaged
  static int getOwnedUtilityCount(List<Property> allProperties) {
    return allProperties
        .where((p) => p.isUtility && p.isOwned && !p.isMortgaged)
        .length;
  }

  /// Utility multiplier: 4x for 1 owned, 10x for both
  static int getUtilityMultiplier(List<Property> allProperties) {
    final count = getOwnedUtilityCount(allProperties);
    if (count >= 2) return 10;
    if (count == 1) return 4;
    return 0;
  }

  /// Whether this property benefits from the color group double-rent bonus
  static bool hasColorGroupBonus(Property property, List<Property> allProperties) {
    return property.isOwned &&
        !property.isMortgaged &&
        property.isStreet &&
        property.houseCount == 0 &&
        ownsFullColorGroup(property.colorGroup, allProperties);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // COLOR GROUP HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  static List<Property> getPropertiesInGroup(ColorGroup group, List<Property> allProperties) {
    return allProperties.where((p) => p.colorGroup == group).toList();
  }

  static bool ownsFullColorGroup(ColorGroup group, List<Property> allProperties) {
    return getPropertiesInGroup(group, allProperties).every((p) => p.isOwned);
  }

  static int getMinHousesInGroup(ColorGroup group, List<Property> allProperties) {
    final ownedInGroup =
        getPropertiesInGroup(group, allProperties).where((p) => p.isOwned).toList();
    if (ownedInGroup.isEmpty) return 0;
    return ownedInGroup.map((p) => p.houseCount).reduce((a, b) => a < b ? a : b);
  }

  static int getMaxHousesInGroup(ColorGroup group, List<Property> allProperties) {
    final ownedInGroup =
        getPropertiesInGroup(group, allProperties).where((p) => p.isOwned).toList();
    if (ownedInGroup.isEmpty) return 0;
    return ownedInGroup.map((p) => p.houseCount).reduce((a, b) => a > b ? a : b);
  }

  static bool groupHasAnyImprovements(ColorGroup group, List<Property> allProperties) {
    return getPropertiesInGroup(group, allProperties).any((p) => p.houseCount > 0);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CAN CHECKS (for UI enable/disable)
  // ─────────────────────────────────────────────────────────────────────────────

  static bool canPurchase(Property property, int cash) {
    return !property.isOwned && cash >= property.purchasePrice;
  }

  static bool canBuildHouse(Property property, List<Property> allProperties, int cash) {
    if (!property.isStreet) return false;
    if (!property.isOwned) return false;
    if (property.isMortgaged) return false;
    if (property.houseCount >= 4) return false;
    if (!ownsFullColorGroup(property.colorGroup, allProperties)) return false;
    if (getPropertiesInGroup(property.colorGroup, allProperties).any((p) => p.isMortgaged)) {
      return false;
    }
    if (property.houseCount > getMinHousesInGroup(property.colorGroup, allProperties)) {
      return false;
    }
    if (cash < property.houseCost) return false;
    return true;
  }

  static bool canBuildHotel(Property property, List<Property> allProperties, int cash) {
    if (!property.isStreet) return false;
    if (!property.isOwned) return false;
    if (property.isMortgaged) return false;
    if (property.houseCount != 4) return false;
    if (!ownsFullColorGroup(property.colorGroup, allProperties)) return false;
    if (getMinHousesInGroup(property.colorGroup, allProperties) < 4) return false;
    if (cash < property.houseCost) return false;
    return true;
  }

  static bool canSellImprovement(Property property, List<Property> allProperties) {
    if (!property.isStreet) return false;
    if (!property.isOwned) return false;
    if (property.houseCount == 0) return false;
    if (property.houseCount < getMaxHousesInGroup(property.colorGroup, allProperties)) {
      return false;
    }
    return true;
  }

  static bool canMortgage(Property property, List<Property> allProperties) {
    if (!property.isOwned) return false;
    if (property.isMortgaged) return false;
    if (property.houseCount > 0) return false;
    if (property.isStreet && groupHasAnyImprovements(property.colorGroup, allProperties)) {
      return false;
    }
    return true;
  }

  static bool canUnmortgage(Property property, int cash) {
    if (!property.isOwned) return false;
    if (!property.isMortgaged) return false;
    if (cash < property.unmortgageCost) return false;
    return true;
  }

  static bool canReleaseProperty(Property property, List<Property> allProperties) {
    if (!property.isOwned) return false;
    if (property.houseCount > 0) return false;
    if (property.isStreet && groupHasAnyImprovements(property.colorGroup, allProperties)) {
      return false;
    }
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ASSET CALCULATIONS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Total asset value: cash + all owned property values
  static int totalAssets(int cash, List<Property> allProperties) {
    final propertyValue = allProperties
        .where((p) => p.isOwned)
        .fold(0, (sum, p) => sum + p.assetValue);
    return cash + propertyValue;
  }
}
