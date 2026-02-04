import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/property.dart';
import '../providers/game_notifier.dart';
import '../providers/providers.dart';

class PropertyDeedDialog extends ConsumerWidget {
  final String propertyId;

  const PropertyDeedDialog({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameNotifierProvider).requireValue;
    final property = state.properties.firstWhere((p) => p.id == propertyId);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(4),
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PropertyHeader(property: property),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Price & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Price: \$${property.purchasePrice}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        _StatusChip(property: property),
                      ],
                    ),
                    const SizedBox(height: 12),

                    /// Rent info (varies by property type)
                    if (property.isStreet)
                      _StreetRentTable(property: property)
                    else if (property.isRailroad)
                      _RailroadRentTable(property: property)
                    else if (property.isUtility)
                      const _UtilityRentInfo(),

                    const SizedBox(height: 8),

                    /// Mortgage info
                    _InfoRow(
                      label: 'Mortgage Value',
                      value: '\$${property.mortgageValue}',
                    ),
                    _InfoRow(
                      label: 'Mortgage Payoff (+10%)',
                      value: '\$${property.unmortgageCost}',
                    ),
                    if (property.isStreet)
                      _InfoRow(
                        label: 'House Cost',
                        value: '\$${property.houseCost}',
                      ),
                    const SizedBox(height: 12),

                    /// Actions
                    _ActionButtons(property: property),
                  ],
                ),
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyHeader extends StatelessWidget {
  final Property property;

  const _PropertyHeader({required this.property});

  @override
  Widget build(BuildContext context) {
    final color = property.colorGroup.color;
    final textColor = _getContrastColor(color);

    return Container(
      color: color,
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      child: Row(
        children: [
          if (property.isRailroad)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.train, color: textColor, size: 24),
            )
          else if (property.isUtility)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                property.id == 'electric' ? Icons.bolt : Icons.water_drop,
                color: textColor,
                size: 24,
              ),
            ),
          Expanded(
            child: Text(
              property.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: textColor),
          ),
        ],
      ),
    );
  }

  Color _getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

class _StatusChip extends StatelessWidget {
  final Property property;

  const _StatusChip({required this.property});

  @override
  Widget build(BuildContext context) {
    Color statusColor() {
      if (property.isMortgaged) {
        return Colors.red.withValues(alpha: 0.2);
      } else if (property.isOwned) {
        return Theme.of(context).colorScheme.primaryContainer;
      } else {
        return Colors.green.withValues(alpha: 0.1);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        property.statusText,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _StreetRentTable extends StatelessWidget {
  final Property property;

  const _StreetRentTable({required this.property});

  @override
  Widget build(BuildContext context) {
    final labels = ['Base', '1 House', '2 Houses', '3 Houses', '4 Houses', 'Hotel'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rent',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: List.generate(6, (index) {
              final isCurrentLevel = property.isOwned && property.houseCount == index;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrentLevel
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.5)
                      : null,
                  border: index < 5
                      ? Border(
                          bottom: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                          ),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isCurrentLevel)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.arrow_right,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        Text(labels[index]),
                      ],
                    ),
                    Text(
                      '\$${property.rentTiers[index]}',
                      style: TextStyle(
                        fontWeight: isCurrentLevel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _RailroadRentTable extends ConsumerWidget {
  final Property property;

  const _RailroadRentTable({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameNotifierProvider);
    final notifier = ref.read(gameNotifierProvider.notifier);
    final labels = ['1 Railroad', '2 Railroads', '3 Railroads', '4 Railroads'];
    final ownedCount = notifier.getOwnedRailroadCount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rent (based on railroads owned)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: List.generate(4, (index) {
              final isCurrentLevel = property.isOwned &&
                  !property.isMortgaged &&
                  ownedCount == index + 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrentLevel
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.5)
                      : null,
                  border: index < 3
                      ? Border(
                          bottom: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.2),
                          ),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isCurrentLevel)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.arrow_right,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        Text(labels[index]),
                      ],
                    ),
                    Text(
                      '\$${property.rentTiers[index]}',
                      style: TextStyle(
                        fontWeight: isCurrentLevel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _UtilityRentInfo extends ConsumerWidget {
  const _UtilityRentInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameNotifierProvider);
    final notifier = ref.read(gameNotifierProvider.notifier);
    final ownedCount = notifier.getOwnedUtilityCount();
    final multiplier = notifier.getUtilityMultiplier();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rent (based on dice roll)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _UtilityRentRow(
                label: '1 Utility owned',
                value: '4× dice roll',
                isActive: ownedCount == 1,
                showBorder: true,
              ),
              _UtilityRentRow(
                label: '2 Utilities owned',
                value: '10× dice roll',
                isActive: ownedCount >= 2,
                showBorder: false,
              ),
            ],
          ),
        ),
        if (ownedCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Current: ${multiplier}× dice roll',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
      ],
    );
  }
}

class _UtilityRentRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isActive;
  final bool showBorder;

  const _UtilityRentRow({
    required this.label,
    required this.value,
    required this.isActive,
    required this.showBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
            : null,
        border: showBorder
            ? Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.arrow_right,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              Text(label),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  final Property property;

  const _ActionButtons({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameNotifierProvider.notifier);

    if (!property.isOwned) {
      return SizedBox(width: double.infinity, child: _buildPurchaseButton(context, notifier));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (property.isStreet && !property.isMortgaged) ...[
          Row(
            children: [
              Expanded(child: _buildHouseButton(context, notifier)),
              const SizedBox(width: 8),
              Expanded(child: _buildSellImprovementButton(context, notifier)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _buildMortgageButton(context, notifier),
        const SizedBox(height: 8),
        _buildReleaseButton(context, notifier),
      ],
    );
  }

  Widget _buildPurchaseButton(BuildContext context, GameNotifier notifier) {
    final canPurchase = notifier.canPurchase(property);
    return FilledButton.icon(
      onPressed: canPurchase
          ? () async {
              final success = await notifier.purchaseProperty(property);
              if (success && context.mounted) {
                _showSnackBar(context, 'Purchased ${property.name}!');
              }
            }
          : null,
      icon: const Icon(Icons.shopping_cart),
      label: Text('Buy for \$${property.purchasePrice}'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.green.shade200,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  Widget _buildHouseButton(BuildContext context, GameNotifier notifier) {
    final canBuildHouse = notifier.canBuildHouse(property);
    final canBuildHotel = notifier.canBuildHotel(property);

    if (canBuildHotel || property.houseCount == 4) {
      return FilledButton.tonal(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: canBuildHotel
            ? () async {
                final success = await notifier.buildHotel(property);
                if (success && context.mounted) {
                  _showSnackBar(context, 'Built hotel on ${property.name}!');
                }
              }
            : null,
        child: Text('Hotel (\$${property.houseCost})'),
      );
    }

    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: canBuildHouse
          ? () async {
              final success = await notifier.buildHouse(property);
              if (success && context.mounted) {
                _showSnackBar(context, 'Built house on ${property.name}!');
              }
            }
          : null,
      child: Text('+ House (\$${property.houseCost})'),
    );
  }

  Widget _buildSellImprovementButton(BuildContext context, GameNotifier notifier) {
    final canSell = notifier.canSellImprovement(property);
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.red.withAlpha(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: canSell
          ? () async {
              final success = await notifier.sellImprovement(property);
              if (success && context.mounted) {
                _showSnackBar(context, 'Sold improvement for \$${property.houseCost ~/ 2}');
              }
            }
          : null,
      child: Text('Sell (+\$${property.houseCost ~/ 2})'),
    );
  }

  Widget _buildMortgageButton(BuildContext context, GameNotifier notifier) {
    if (property.isMortgaged) {
      final canUnmortgage = notifier.canUnmortgage(property);
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: canUnmortgage
            ? () async {
                final success = await notifier.unmortgage(property);
                if (success && context.mounted) {
                  _showSnackBar(context, 'Unmortgaged ${property.name}');
                }
              }
            : null,
        child: Text('Unmortgage (\$${property.unmortgageCost})'),
      );
    }

    final canMortgage = notifier.canMortgage(property);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: canMortgage
          ? () async {
              final success = await notifier.mortgage(property);
              if (success && context.mounted) {
                _showSnackBar(context, 'Mortgaged for \$${property.mortgageValue}');
              }
            }
          : null,
      child: Text('Mortgage (+\$${property.mortgageValue})'),
    );
  }

  Widget _buildReleaseButton(BuildContext context, GameNotifier notifier) {
    final canRelease = notifier.canReleaseProperty(property);
    return OutlinedButton.icon(
      onPressed: canRelease ? () => _showReleaseConfirmation(context, notifier) : null,
      icon: const Icon(Icons.output),
      label: const Text('Release Property'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  void _showReleaseConfirmation(BuildContext context, GameNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release Property?'),
        content: Text(
          'Release ${property.name} to settle a debt?\n\n'
          'No cash will be returned. This simulates trading the property to another player.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await notifier.releaseProperty(property);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Released ${property.name}')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Release'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
