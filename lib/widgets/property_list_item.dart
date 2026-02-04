import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../providers/game_provider.dart';

class PropertyListItem extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const PropertyListItem({super.key, required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(150), width: 1),
        color: property.colorGroup.color,
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  /// Property info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Owned vs Available property card
                        if (property.isOwned) ...[
                          /// If owned, show property name, price, rent info, and collect button
                          _buildPlayerOwnedPropertyCard(context),
                        ] else ...[
                          /// If not owned, show property name, price, and show info button
                          _buildAvailablePropertyCard(context),
                        ],

                        ///
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    /// END build
  }

  /// Build available property card
  Widget _buildAvailablePropertyCard(BuildContext context) {
    return Builder(
      builder: (context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ///
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Property name
                Text(
                  property.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: property.isMortgaged ? TextDecoration.lineThrough : null,
                      ),
                ),

                /// Property price
                Text(
                  'Price: \$${property.purchasePrice}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),

            /// Property info button
            ElevatedButton(
              onPressed: () {
                onTap();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: const Text('Property Info >'),
            ),

            ///
          ],
        );

        ///
      },
    );
  }

  /// Build owned property card
  Widget _buildPlayerOwnedPropertyCard(BuildContext context) {
    return Builder(
      builder: (context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ///
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Purchase price: \$${property.purchasePrice}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                _buildRentInfo(context),
              ],
            ),

            ///
            if (property.isMortgaged) ...[

              /// Mortgaged property icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Icon(
                  Icons.block,
                  color: Colors.red.shade700,
                  size: 32,
                ),
              ),

            ] else ...[

              /// Collect Rent button
              ElevatedButton(
                onPressed: () {
                  _collectRent(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: const Text('Collect Rent'),
              ),

              ///
            ],
          ],
        );

        ///
      },
    );
  }

  /// Build rent info widget
  Widget _buildRentInfo(BuildContext context) {
    final provider = context.watch<GameProvider>();

    var actualRent = provider.getRentDisplayString(property);

    final hasBonus = provider.hasColorGroupBonus(property);

    return Row(
      children: [
        Text(
          'Rent: $actualRent',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: property.isMortgaged ? Theme.of(context).colorScheme.outline : Colors.green.shade800,
                fontSize: 16,
              ),
        ),
        if (hasBonus) ...[
          Text(
            ' (Base 2x)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        _PropertyStatusBadge(property: property),
      ],
    );

    ///
  }

  /// Handle Property rent collection
  void _collectRent(BuildContext context) {
    if (kDebugMode) print('Collect rent for ${property.name}');

    final provider = context.read<GameProvider>();

    /// If property is a utility, prompt for dice roll value
    if (property.isUtility) {
      /// Show dialog to input dice roll
      showDialog(
        context: context,
        builder: (dialogContext) {
          final TextEditingController diceController = TextEditingController();

          return AlertDialog(
            title: const Text('Utility Rent Collection'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter the sum of the dice rolled by the player landing on your utility property. The value must be between 2 and 12.'),
                const SizedBox(height: 12),
                TextField(
                  controller: diceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Value of Dice Roll',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final diceRoll = int.tryParse(diceController.text);

                  if (diceRoll == null || diceRoll < 2 || diceRoll > 12) {
                    return;
                  }

                  final multiplier = provider.getUtilityMultiplier();
                  final rentValue = diceRoll * multiplier;

                  if (kDebugMode) print('Utility rent: $diceRoll x $multiplier = $rentValue');

                  Navigator.of(dialogContext).pop();

                  final success = await provider.adjustCash(rentValue);

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Collected \$$rentValue from ${property.name}')),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );

      return;
    }

    /// Get actual rent amount
    var rentDisplayString = provider.getRentDisplayString(property);
    int rentValue = provider.getActualRentValue(property);
    final hasBonus = provider.hasColorGroupBonus(property);

    if (kDebugMode) print('Collecting rent: $rentDisplayString (from base rent: ${property.currentRent}, bonus applied: $hasBonus)');

    /// Throw Confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Collect Rent'),
          content: Text('Collect $rentDisplayString rent from player landing on ${property.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final success = await provider.adjustCash(rentValue);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Collected $rentDisplayString from ${property.name}')),
                  );
                }
              },
              child: const Text('Collect Rent'),
            ),
          ],
        );
      },
    );
  }

  ///
}

/// Status badge widget
class _PropertyStatusBadge extends StatelessWidget {
  final Property property;

  const _PropertyStatusBadge({required this.property});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _getColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        property.statusText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  (Color, Color) _getColors(BuildContext context) {
    if (!property.isOwned) {
      return (Colors.green.shade700, Colors.green.withValues(alpha: 0.1));
    }
    if (property.isMortgaged) {
      return (Colors.orange.shade700, Colors.orange.withValues(alpha: 0.1));
    }
    if (property.hasHotel || property.houseCount > 0) {
      return (Colors.blue.shade700, Colors.blue.withValues(alpha: 0.1));
    }
    return (Theme.of(context).colorScheme.outline, Theme.of(context).colorScheme.surfaceContainerHighest);
  }
}
