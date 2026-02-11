import 'package:flutter_test/flutter_test.dart';
import '../fixtures/test_properties.dart';
import '../../lib/models/property.dart';
import '../../lib/models/color_group.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // PROPERTY TYPE CLASSIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  group('Property Type Classification', () {
    test('street properties return isStreet true', () {
      final property = mediterranean();

      expect(property.isStreet, true);
      expect(property.isRailroad, false);
      expect(property.isUtility, false);
    });

    test('railroads return isRailroad true', () {
      final property = readingRailroad();

      expect(property.isStreet, false);
      expect(property.isRailroad, true);
      expect(property.isUtility, false);
    });

    test('utilities return isUtility true', () {
      final property = electricCompany();

      expect(property.isStreet, false);
      expect(property.isRailroad, false);
      expect(property.isUtility, true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // MORTGAGE CALCULATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Mortgage Calculations', () {
    test('mortgage value is half of purchase price', () {
      final mediterranean = Property(
        id: 'test',
        name: 'Test',
        colorGroup: ColorGroup.brown,
        purchasePrice: 60,
        rentTiers: [2, 10, 30, 90, 160, 250],
      );

      expect(mediterranean.mortgageValue, 30);

      final boardwalk = Property(
        id: 'test2',
        name: 'Test2',
        colorGroup: ColorGroup.darkBlue,
        purchasePrice: 400,
        rentTiers: [50, 200, 600, 1400, 1700, 2000],
      );

      expect(boardwalk.mortgageValue, 200);
    });

    test('unmortgage cost is mortgage value plus 10%', () {
      final property = Property(
        id: 'test',
        name: 'Test',
        colorGroup: ColorGroup.brown,
        purchasePrice: 60,
        rentTiers: [2, 10, 30, 90, 160, 250],
      );

      // Mortgage value = 30, unmortgage = 30 * 1.1 = 33
      expect(property.unmortgageCost, 33);
    });

    test('unmortgage cost uses ceil for rounding', () {
      final property = Property(
        id: 'test',
        name: 'Test',
        colorGroup: ColorGroup.railroad,
        purchasePrice: 200,
        rentTiers: [25, 50, 100, 200],
      );

      // Mortgage value = 100, unmortgage = ceil(100 * 1.1)
      // Note: floating point makes 100 * 1.1 slightly > 110, so ceil = 111
      expect(property.unmortgageCost, 111);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // HOUSE COST
  // ═══════════════════════════════════════════════════════════════════════════

  group('House Cost', () {
    test('house cost comes from color group', () {
      expect(mediterranean().houseCost, 50); // Brown = $50
      expect(boardwalk().houseCost, 200); // Dark Blue = $200
    });

    test('railroads have zero house cost', () {
      expect(readingRailroad().houseCost, 0);
    });

    test('utilities have zero house cost', () {
      expect(electricCompany().houseCost, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // HOTEL DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  group('Hotel Detection', () {
    test('hasHotel is true when street has 5 houses', () {
      final property = mediterranean(isOwned: true, houseCount: 5);

      expect(property.hasHotel, true);
    });

    test('hasHotel is false when street has fewer than 5 houses', () {
      expect(mediterranean(isOwned: true, houseCount: 0).hasHotel, false);
      expect(mediterranean(isOwned: true, houseCount: 4).hasHotel, false);
    });

    test('hasHotel is always false for non-street properties', () {
      // Even if somehow houseCount were set (shouldn't happen)
      final railroad = Property(
        id: 'test',
        name: 'Test Railroad',
        colorGroup: ColorGroup.railroad,
        purchasePrice: 200,
        rentTiers: [25, 50, 100, 200],
        houseCount: 5,
      );

      expect(railroad.hasHotel, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // CURRENT RENT (STREETS ONLY)
  // ═══════════════════════════════════════════════════════════════════════════

  group('Current Rent', () {
    test('returns base rent when no houses', () {
      final property = mediterranean(isOwned: true);

      expect(property.currentRent, 2); // rentTiers[0]
    });

    test('returns rent tier based on house count', () {
      expect(mediterranean(isOwned: true, houseCount: 1).currentRent, 10);
      expect(mediterranean(isOwned: true, houseCount: 2).currentRent, 30);
      expect(mediterranean(isOwned: true, houseCount: 3).currentRent, 90);
      expect(mediterranean(isOwned: true, houseCount: 4).currentRent, 160);
      expect(mediterranean(isOwned: true, houseCount: 5).currentRent, 250); // Hotel
    });

    test('returns zero when mortgaged', () {
      final property = mediterranean(isOwned: true, houseCount: 3, isMortgaged: true);

      expect(property.currentRent, 0);
    });

    test('returns zero for railroads (handled by GameRules)', () {
      final property = readingRailroad(isOwned: true);

      expect(property.currentRent, 0);
    });

    test('returns zero for utilities (handled by GameRules)', () {
      final property = electricCompany(isOwned: true);

      expect(property.currentRent, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // IMPROVEMENT VALUE
  // ═══════════════════════════════════════════════════════════════════════════

  group('Improvement Value', () {
    test('returns zero for properties with no houses', () {
      final property = mediterranean(isOwned: true);

      expect(property.improvementValue, 0);
    });

    test('returns house cost times house count', () {
      // Brown house cost = $50
      expect(mediterranean(isOwned: true, houseCount: 1).improvementValue, 50);
      expect(mediterranean(isOwned: true, houseCount: 2).improvementValue, 100);
      expect(mediterranean(isOwned: true, houseCount: 4).improvementValue, 200);
    });

    test('hotel counts as 5 houses', () {
      // Brown house cost = $50, hotel = 5 × $50 = $250
      final property = mediterranean(isOwned: true, houseCount: 5);

      expect(property.improvementValue, 250);
    });

    test('returns zero for railroads', () {
      final property = readingRailroad(isOwned: true);

      expect(property.improvementValue, 0);
    });

    test('returns zero for utilities', () {
      final property = electricCompany(isOwned: true);

      expect(property.improvementValue, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ASSET VALUE
  // ═══════════════════════════════════════════════════════════════════════════

  group('Asset Value', () {
    test('equals purchase price when no improvements', () {
      final property = mediterranean(isOwned: true);

      expect(property.assetValue, 60);
    });

    test('includes improvement value', () {
      // $60 purchase + (2 houses × $50) = $160
      final property = mediterranean(isOwned: true, houseCount: 2);

      expect(property.assetValue, 160);
    });

    test('equals mortgage value when mortgaged', () {
      // Mortgaged: only counts at $30 (half of $60)
      final property = mediterranean(isOwned: true, isMortgaged: true);

      expect(property.assetValue, 30);
    });

    test('mortgaged value ignores houses (edge case - should not happen)', () {
      // If somehow a property were mortgaged with houses (invalid state),
      // asset value should still be mortgage value
      final property = mediterranean(isOwned: true, houseCount: 2, isMortgaged: true);

      expect(property.assetValue, 30);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS TEXT
  // ═══════════════════════════════════════════════════════════════════════════

  group('Status Text', () {
    test('returns bullet for unowned property', () {
      final property = mediterranean();

      expect(property.statusText, '•');
    });

    test('returns "Owned" for owned property with no improvements', () {
      final property = mediterranean(isOwned: true);

      expect(property.statusText, 'Owned');
    });

    test('returns "Mortgaged" for mortgaged property', () {
      final property = mediterranean(isOwned: true, isMortgaged: true);

      expect(property.statusText, 'Mortgaged');
    });

    test('returns house count for properties with houses', () {
      expect(mediterranean(isOwned: true, houseCount: 1).statusText, '1 House');
      expect(mediterranean(isOwned: true, houseCount: 2).statusText, '2 Houses');
      expect(mediterranean(isOwned: true, houseCount: 4).statusText, '4 Houses');
    });

    test('returns "Hotel" for properties with 5 houses', () {
      final property = mediterranean(isOwned: true, houseCount: 5);

      expect(property.statusText, 'Hotel');
    });

    test('returns "Owned" for owned railroads', () {
      final property = readingRailroad(isOwned: true);

      expect(property.statusText, 'Owned');
    });

    test('returns "Owned" for owned utilities', () {
      final property = electricCompany(isOwned: true);

      expect(property.statusText, 'Owned');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // COPY WITH
  // ═══════════════════════════════════════════════════════════════════════════

  group('copyWith', () {
    test('creates a new instance with specified fields changed', () {
      final original = mediterranean();
      final copy = original.copyWith(isOwned: true, houseCount: 3);

      expect(copy.isOwned, true);
      expect(copy.houseCount, 3);
      expect(copy.isMortgaged, false); // Unchanged
      expect(copy.id, original.id); // Immutable fields preserved
      expect(copy.name, original.name);
      expect(copy.purchasePrice, original.purchasePrice);
    });

    test('preserves all fields when no arguments provided', () {
      final original = mediterranean(isOwned: true, houseCount: 2, isMortgaged: false);
      final copy = original.copyWith();

      expect(copy.isOwned, original.isOwned);
      expect(copy.houseCount, original.houseCount);
      expect(copy.isMortgaged, original.isMortgaged);
    });
  });
}
