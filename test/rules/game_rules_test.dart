import 'package:flutter_test/flutter_test.dart';
import 'package:hsoa_opoly/models/color_group.dart';
import 'package:hsoa_opoly/rules/game_rules.dart';

import '../fixtures/test_properties.dart';

void main() {
  print('\n${'═' * 70}');
  print('GAME RULES TEST SUITE');
  print('Testing pure Dart business logic — shared across all state management branches');
  print('${'═' * 70}\n');
  // ═══════════════════════════════════════════════════════════════════════════
  // RENT CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  group('Rent Calculation', () {
    setUpAll(() => print('\n▶ RENT CALCULATION'));

    group('Street Properties', () {
      setUpAll(() => print('  ├─ Street Properties'));
      test('base rent when property is owned without color group monopoly', () {
        final properties = brownColorGroup(
          mediterraneanOwned: true,
          balticOwned: false, // Don't own full group
        );
        final mediterranean = properties[0];

        final rent = GameRules.getActualRentValue(mediterranean, properties);

        expect(rent, 2); // Base rent from rentTiers[0]
      });

      test('double rent when player owns full color group (no houses)', () {
        final properties = brownColorGroup(
          mediterraneanOwned: true,
          balticOwned: true, // Own full group
        );
        final mediterranean = properties[0];

        final rent = GameRules.getActualRentValue(mediterranean, properties);

        expect(rent, 4); // Base rent (2) × 2 = 4
      });

      test('rent increases with houses', () {
        final properties = brownColorGroup(
          mediterraneanOwned: true,
          balticOwned: true,
          mediterraneanHouses: 3,
          balticHouses: 3,
        );
        final mediterranean = properties[0];

        final rent = GameRules.getActualRentValue(mediterranean, properties);

        expect(rent, 90); // rentTiers[3] for 3 houses
      });

      test('hotel rent (5 houses)', () {
        final properties = brownColorGroup(
          mediterraneanOwned: true,
          balticOwned: true,
          mediterraneanHouses: 5,
          balticHouses: 5,
        );
        final mediterranean = properties[0];

        final rent = GameRules.getActualRentValue(mediterranean, properties);

        expect(rent, 250); // rentTiers[5] for hotel
      });

      test('mortgaged property returns zero rent', () {
        final properties = brownColorGroup(
          mediterraneanOwned: true,
          balticOwned: true,
          mediterraneanMortgaged: true,
        );
        final mediterranean = properties[0];

        final rent = GameRules.getActualRentValue(mediterranean, properties);

        expect(rent, 0);
      });

      test('color group bonus does not apply when houses are built', () {
        final properties = brownColorGroup(
          mediterraneanOwned: true,
          balticOwned: true,
          mediterraneanHouses: 1, // Has a house
        );
        final mediterranean = properties[0];

        final rent = GameRules.getActualRentValue(mediterranean, properties);

        // Should be house rent (10), NOT base rent × 2
        expect(rent, 10);
      });
    });

    group('Railroad Properties', () {
      setUpAll(() => print('  ├─ Railroad Properties'));
      test('rent scales with number of railroads owned', () {
        final railroads = allRailroads(readingOwned: true);
        expect(
          GameRules.getRailroadRent(railroads[0], railroads),
          25, // 1 railroad = $25
        );

        final twoOwned = allRailroads(readingOwned: true, pennsylvaniaOwned: true);
        expect(
          GameRules.getRailroadRent(twoOwned[0], twoOwned),
          50, // 2 railroads = $50
        );

        final threeOwned = allRailroads(
          readingOwned: true,
          pennsylvaniaOwned: true,
          boOwned: true,
        );
        expect(
          GameRules.getRailroadRent(threeOwned[0], threeOwned),
          100, // 3 railroads = $100
        );

        final allOwned = allRailroads(
          readingOwned: true,
          pennsylvaniaOwned: true,
          boOwned: true,
          shortLineOwned: true,
        );
        expect(
          GameRules.getRailroadRent(allOwned[0], allOwned),
          200, // 4 railroads = $200
        );
      });

      test('mortgaged railroad does not count toward owned count', () {
        final railroads = allRailroads(
          readingOwned: true,
          pennsylvaniaOwned: true,
          pennsylvaniaMortgaged: true, // Owned but mortgaged
        );

        // Reading should only get 1-railroad rent since Penn is mortgaged
        expect(
          GameRules.getRailroadRent(railroads[0], railroads),
          25,
        );
      });

      test('mortgaged railroad returns zero rent', () {
        final railroads = allRailroads(
          readingOwned: true,
          readingMortgaged: true,
        );

        expect(
          GameRules.getRailroadRent(railroads[0], railroads),
          0,
        );
      });
    });

    group('Utility Properties', () {
      setUpAll(() => print('  ├─ Utility Properties'));
      test('one utility owned returns 4x multiplier', () {
        final utilities = bothUtilities(electricOwned: true);

        expect(GameRules.getUtilityMultiplier(utilities), 4);
      });

      test('both utilities owned returns 10x multiplier', () {
        final utilities = bothUtilities(
          electricOwned: true,
          waterOwned: true,
        );

        expect(GameRules.getUtilityMultiplier(utilities), 10);
      });

      test('no utilities owned returns 0 multiplier', () {
        final utilities = bothUtilities();

        expect(GameRules.getUtilityMultiplier(utilities), 0);
      });

      test('mortgaged utility does not count toward owned count', () {
        final utilities = bothUtilities(
          electricOwned: true,
          waterOwned: true,
          waterMortgaged: true,
        );

        // Only electric counts, so 4x not 10x
        expect(GameRules.getUtilityMultiplier(utilities), 4);
      });
    });

    group('Rent Display String', () {
      setUpAll(() => print('  └─ Rent Display String'));
      test('street property shows dollar amount', () {
        final properties = brownColorGroup(mediterraneanOwned: true);

        expect(
          GameRules.getRentDisplayString(properties[0], properties),
          '\$2',
        );
      });

      test('utility shows dice roll multiplier', () {
        final utilities = bothUtilities(electricOwned: true);

        expect(
          GameRules.getRentDisplayString(utilities[0], utilities),
          'Dice roll x4',
        );
      });

      test('mortgaged property shows \$0', () {
        final properties = brownColorGroup(
          mediterraneanOwned: true,
          mediterraneanMortgaged: true,
        );

        expect(
          GameRules.getRentDisplayString(properties[0], properties),
          '\$0',
        );
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // COLOR GROUP BONUS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Color Group Bonus', () {
    setUpAll(() => print('\n▶ COLOR GROUP BONUS'));
    test('hasColorGroupBonus returns true when owning full group with no houses', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
      );

      expect(GameRules.hasColorGroupBonus(properties[0], properties), true);
      expect(GameRules.hasColorGroupBonus(properties[1], properties), true);
    });

    test('hasColorGroupBonus returns false when not owning full group', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: false,
      );

      expect(GameRules.hasColorGroupBonus(properties[0], properties), false);
    });

    test('hasColorGroupBonus returns false when property has houses', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 1,
      );

      expect(GameRules.hasColorGroupBonus(properties[0], properties), false);
    });

    test('hasColorGroupBonus returns false when property is mortgaged', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanMortgaged: true,
      );

      expect(GameRules.hasColorGroupBonus(properties[0], properties), false);
    });

    test('hasColorGroupBonus returns false for railroads', () {
      final railroads = allRailroads(
        readingOwned: true,
        pennsylvaniaOwned: true,
        boOwned: true,
        shortLineOwned: true,
      );

      expect(GameRules.hasColorGroupBonus(railroads[0], railroads), false);
    });

    test('hasColorGroupBonus returns false for utilities', () {
      final utilities = bothUtilities(
        electricOwned: true,
        waterOwned: true,
      );

      expect(GameRules.hasColorGroupBonus(utilities[0], utilities), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // EVEN-BUILD RULE
  // ═══════════════════════════════════════════════════════════════════════════

  group('Even-Build Rule (canBuildHouse)', () {
    setUpAll(() => print('\n▶ EVEN-BUILD RULE (canBuildHouse)'));
    test('can build when all properties in group have same house count', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 1,
        balticHouses: 1,
      );

      expect(GameRules.canBuildHouse(properties[0], properties, 1000), true);
      expect(GameRules.canBuildHouse(properties[1], properties, 1000), true);
    });

    test('cannot build if property already has more houses than another in group', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 2, // Has more houses
        balticHouses: 1,
      );

      // Mediterranean can't build because it's already ahead
      expect(GameRules.canBuildHouse(properties[0], properties, 1000), false);
      // Baltic can build because it's behind
      expect(GameRules.canBuildHouse(properties[1], properties, 1000), true);
    });

    test('cannot build house without owning full color group', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: false,
      );

      expect(GameRules.canBuildHouse(properties[0], properties, 1000), false);
    });

    test('cannot build house if any property in group is mortgaged', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        balticMortgaged: true,
      );

      expect(GameRules.canBuildHouse(properties[0], properties, 1000), false);
    });

    test('cannot build house if property already has 4 houses', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 4,
        balticHouses: 4,
      );

      expect(GameRules.canBuildHouse(properties[0], properties, 1000), false);
    });

    test('cannot build house if insufficient cash', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
      );

      // Brown group house cost is $50
      expect(GameRules.canBuildHouse(properties[0], properties, 49), false);
      expect(GameRules.canBuildHouse(properties[0], properties, 50), true);
    });

    test('cannot build house on railroad', () {
      final railroads = allRailroads(
        readingOwned: true,
        pennsylvaniaOwned: true,
        boOwned: true,
        shortLineOwned: true,
      );

      expect(GameRules.canBuildHouse(railroads[0], railroads, 1000), false);
    });

    test('cannot build house on utility', () {
      final utilities = bothUtilities(
        electricOwned: true,
        waterOwned: true,
      );

      expect(GameRules.canBuildHouse(utilities[0], utilities, 1000), false);
    });
  });

  group('Even-Build Rule (canBuildHotel)', () {
    setUpAll(() => print('\n▶ EVEN-BUILD RULE (canBuildHotel)'));
    test('can build hotel when property has 4 houses and all in group have 4', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 4,
        balticHouses: 4,
      );

      expect(GameRules.canBuildHotel(properties[0], properties, 1000), true);
    });

    test('cannot build hotel if any property in group has fewer than 4 houses', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 4,
        balticHouses: 3, // Only 3 houses
      );

      expect(GameRules.canBuildHotel(properties[0], properties, 1000), false);
    });

    test('cannot build hotel if property does not have exactly 4 houses', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 3, // Only 3 houses
        balticHouses: 4,
      );

      expect(GameRules.canBuildHotel(properties[0], properties, 1000), false);
    });
  });

  group('Even-Build Rule (canSellImprovement)', () {
    setUpAll(() => print('\n▶ EVEN-BUILD RULE (canSellImprovement)'));
    test('can sell improvement when property has most houses in group', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 3,
        balticHouses: 2,
      );

      // Mediterranean has 3, Baltic has 2 — can sell from Mediterranean
      expect(GameRules.canSellImprovement(properties[0], properties), true);
      // Cannot sell from Baltic because Mediterranean has more
      expect(GameRules.canSellImprovement(properties[1], properties), false);
    });

    test('can sell from either when both have same house count', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 2,
        balticHouses: 2,
      );

      expect(GameRules.canSellImprovement(properties[0], properties), true);
      expect(GameRules.canSellImprovement(properties[1], properties), true);
    });

    test('cannot sell if property has no houses', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
      );

      expect(GameRules.canSellImprovement(properties[0], properties), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // MORTGAGE RULES
  // ═══════════════════════════════════════════════════════════════════════════

  group('Mortgage Rules', () {
    setUpAll(() => print('\n▶ MORTGAGE RULES'));

    group('canMortgage', () {
      setUpAll(() => print('  ├─ canMortgage'));
      test('can mortgage owned property with no improvements', () {
        final properties = brownColorGroup(
          mediterraneanOwned: true,
          balticOwned: true,
        );

        expect(GameRules.canMortgage(properties[0], properties), true);
      });

      test('cannot mortgage property with houses', () {
        final properties = brownColorGroup(
          mediterraneanOwned: true,
          balticOwned: true,
          mediterraneanHouses: 1,
        );

        expect(GameRules.canMortgage(properties[0], properties), false);
      });

      test('cannot mortgage if any property in color group has improvements', () {
        final properties = brownColorGroup(
          mediterraneanOwned: true,
          balticOwned: true,
          balticHouses: 1, // Baltic has a house
        );

        // Mediterranean has no houses, but Baltic does — can't mortgage Mediterranean
        expect(GameRules.canMortgage(properties[0], properties), false);
      });

      test('cannot mortgage already mortgaged property', () {
        final properties = brownColorGroup(
          mediterraneanOwned: true,
          balticOwned: true,
          mediterraneanMortgaged: true,
        );

        expect(GameRules.canMortgage(properties[0], properties), false);
      });

      test('cannot mortgage unowned property', () {
        final properties = brownColorGroup();

        expect(GameRules.canMortgage(properties[0], properties), false);
      });

      test('can mortgage railroad', () {
        final railroads = allRailroads(readingOwned: true);

        expect(GameRules.canMortgage(railroads[0], railroads), true);
      });

      test('can mortgage utility', () {
        final utilities = bothUtilities(electricOwned: true);

        expect(GameRules.canMortgage(utilities[0], utilities), true);
      });
    });

    group('canUnmortgage', () {
      setUpAll(() => print('  └─ canUnmortgage'));
      test('can unmortgage when property is mortgaged and have enough cash', () {
        final property = mediterranean(isOwned: true, isMortgaged: true);

        // Unmortgage cost = mortgage value × 1.1 = 30 × 1.1 = 33
        expect(GameRules.canUnmortgage(property, 33), true);
        expect(GameRules.canUnmortgage(property, 32), false);
      });

      test('cannot unmortgage property that is not mortgaged', () {
        final property = mediterranean(isOwned: true, isMortgaged: false);

        expect(GameRules.canUnmortgage(property, 1000), false);
      });

      test('cannot unmortgage unowned property', () {
        final property = mediterranean(isOwned: false, isMortgaged: true);

        expect(GameRules.canUnmortgage(property, 1000), false);
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PURCHASE RULES
  // ═══════════════════════════════════════════════════════════════════════════

  group('Purchase Rules', () {
    setUpAll(() => print('\n▶ PURCHASE RULES'));
    test('can purchase unowned property with sufficient cash', () {
      final property = mediterranean();

      expect(GameRules.canPurchase(property, 60), true);
      expect(GameRules.canPurchase(property, 100), true);
    });

    test('cannot purchase with insufficient cash', () {
      final property = mediterranean();

      expect(GameRules.canPurchase(property, 59), false);
    });

    test('cannot purchase already owned property', () {
      final property = mediterranean(isOwned: true);

      expect(GameRules.canPurchase(property, 1000), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RELEASE PROPERTY RULES
  // ═══════════════════════════════════════════════════════════════════════════

  group('Release Property Rules', () {
    setUpAll(() => print('\n▶ RELEASE PROPERTY RULES'));
    test('can release owned property with no improvements', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
      );

      expect(GameRules.canReleaseProperty(properties[0], properties), true);
    });

    test('cannot release property with houses', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 1,
      );

      expect(GameRules.canReleaseProperty(properties[0], properties), false);
    });

    test('cannot release if any property in color group has improvements', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        balticHouses: 1,
      );

      expect(GameRules.canReleaseProperty(properties[0], properties), false);
    });

    test('cannot release unowned property', () {
      final property = mediterranean();

      expect(GameRules.canReleaseProperty(property, [property]), false);
    });

    test('can release mortgaged property', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanMortgaged: true,
      );

      expect(GameRules.canReleaseProperty(properties[0], properties), true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ASSET CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  group('Asset Calculation', () {
    setUpAll(() => print('\n▶ ASSET CALCULATION'));
    test('total assets equals cash when no properties owned', () {
      final properties = brownColorGroup();

      expect(GameRules.totalAssets(1500, properties), 1500);
    });

    test('owned property adds purchase price to assets', () {
      final properties = brownColorGroup(mediterraneanOwned: true);

      expect(GameRules.totalAssets(1500, properties), 1560); // 1500 + 60
    });

    test('houses add to property value', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 2,
      );
      // Mediterranean: $60 purchase + (2 houses × $50) = $160
      // Baltic: $60 purchase
      // Cash: $1500
      // Total: $1720

      expect(GameRules.totalAssets(1500, properties), 1720);
    });

    test('hotel adds 5 house values to property', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 5, // Hotel
      );
      // Mediterranean: $60 purchase + (5 × $50) = $310
      // Baltic: $60 purchase
      // Cash: $1500
      // Total: $1870

      expect(GameRules.totalAssets(1500, properties), 1870);
    });

    test('mortgaged property counts at mortgage value only', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        mediterraneanMortgaged: true,
      );
      // Mediterranean mortgaged: $30 (half of $60)
      // Cash: $1500
      // Total: $1530

      expect(GameRules.totalAssets(1500, properties), 1530);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // COLOR GROUP HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  group('Color Group Helpers', () {
    setUpAll(() => print('\n▶ COLOR GROUP HELPERS'));
    test('ownsFullColorGroup returns true when all properties in group are owned', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
      );

      expect(
        GameRules.ownsFullColorGroup(ColorGroup.brown, properties),
        true,
      );
    });

    test('ownsFullColorGroup returns false when not all properties are owned', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: false,
      );

      expect(
        GameRules.ownsFullColorGroup(ColorGroup.brown, properties),
        false,
      );
    });

    test('getMinHousesInGroup returns minimum house count among owned', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 3,
        balticHouses: 1,
      );

      expect(
        GameRules.getMinHousesInGroup(ColorGroup.brown, properties),
        1,
      );
    });

    test('getMaxHousesInGroup returns maximum house count among owned', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 3,
        balticHouses: 1,
      );

      expect(
        GameRules.getMaxHousesInGroup(ColorGroup.brown, properties),
        3,
      );
    });

    test('groupHasAnyImprovements returns true if any property has houses', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
        mediterraneanHouses: 1,
      );

      expect(
        GameRules.groupHasAnyImprovements(ColorGroup.brown, properties),
        true,
      );
    });

    test('groupHasAnyImprovements returns false if no properties have houses', () {
      final properties = brownColorGroup(
        mediterraneanOwned: true,
        balticOwned: true,
      );

      expect(
        GameRules.groupHasAnyImprovements(ColorGroup.brown, properties),
        false,
      );
    });
  });
}
