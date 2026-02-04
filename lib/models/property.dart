import 'color_group.dart';

class Property {
  final String id;
  final String name;
  final ColorGroup colorGroup;
  final int purchasePrice;
  final List<int> rentTiers; // Streets: [base, 1house, 2house, 3house, 4house, hotel]
                              // Railroads: [1owned, 2owned, 3owned, 4owned]
                              // Utilities: empty (calculated by dice)

  // Mutable state
  bool isOwned;
  int houseCount; // 0-4, or 5 means hotel (streets only)
  bool isMortgaged;

  Property({
    required this.id,
    required this.name,
    required this.colorGroup,
    required this.purchasePrice,
    required this.rentTiers,
    this.isOwned = false,
    this.houseCount = 0,
    this.isMortgaged = false,
  });

  bool get isStreet => colorGroup.isStreet;
  bool get isRailroad => colorGroup == ColorGroup.railroad;
  bool get isUtility => colorGroup == ColorGroup.utility;

  int get mortgageValue => purchasePrice ~/ 2;

  int get unmortgageCost => (mortgageValue * 1.1).ceil();

  int get houseCost => colorGroup.houseCost;

  bool get hasHotel => isStreet && houseCount == 5;

  /// Current rent tier for streets only (railroads/utilities handled by provider)
  int get currentRent {
    if (isMortgaged) return 0;
    if (!isStreet) return 0; // Handled elsewhere
    if (houseCount == 0) return rentTiers[0];
    return rentTiers[houseCount];
  }

  /// Value of improvements on this property (for total assets calculation)
  int get improvementValue {
    if (!isStreet) return 0;
    if (hasHotel) {
      return houseCost * 5;
    }
    return houseCount * houseCost;
  }

  /// Total asset value of this property
  int get assetValue {
    if (isMortgaged) return mortgageValue;
    return purchasePrice + improvementValue;
  }

  String get statusText {
    if (!isOwned) return '•';
    if (isMortgaged) return 'Mortgaged';
    if (!isStreet) return 'Owned';
    if (hasHotel) return 'Hotel';
    if (houseCount > 0) return '$houseCount House${houseCount > 1 ? 's' : ''}';
    return 'Owned';

  }

  Property copyWith({
    bool? isOwned,
    int? houseCount,
    bool? isMortgaged,
  }) {
    return Property(
      id: id,
      name: name,
      colorGroup: colorGroup,
      purchasePrice: purchasePrice,
      rentTiers: rentTiers,
      isOwned: isOwned ?? this.isOwned,
      houseCount: houseCount ?? this.houseCount,
      isMortgaged: isMortgaged ?? this.isMortgaged,
    );
  }
}
