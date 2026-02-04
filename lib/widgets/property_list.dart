import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'property_list_item.dart';
import 'property_deed_dialog.dart';

class PropertyList extends ConsumerWidget {

  /// Pass Go Function from Parent Widget
  final VoidCallback onPassGo;

  PropertyList({super.key, required this.onPassGo});

  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameNotifierProvider).requireValue;
    final properties = state.properties;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      itemCount: properties.length + 1,
      itemBuilder: (context, index) {
        if (index == properties.length) {
          return _buildPassGoButton(context);
        }

        final property = properties[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PropertyListItem(
            property: property,
            onTap: () => _showPropertyDetail(context, property.id),
          ),
        );
      },
    );
  }

  Widget _buildPassGoButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        onPassGo();
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
          border: Border.all(color: Colors.black87, width: 2),
        ),
        alignment: Alignment.center,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Text('PASS GO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showPropertyDetail(BuildContext context, String propertyId) {
    showDialog(
      context: context,
      builder: (_) => PropertyDeedDialog(propertyId: propertyId),
    );
  }
}
