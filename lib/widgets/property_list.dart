import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import 'property_list_item.dart';
import 'property_deed_dialog.dart';

class PropertyList extends StatelessWidget {

  /// Pass Go Function from Parent Widget
  final VoidCallback onPassGo;

  PropertyList({super.key, required this.onPassGo});

  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameCubit>().state as GameLoaded;
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
    final cubit = context.read<GameCubit>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: PropertyDeedDialog(propertyId: propertyId),
      ),
    );
  }
}
