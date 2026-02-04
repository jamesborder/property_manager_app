import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/game_cubit.dart';
import '../widgets/assets_footer.dart';
import '../widgets/balance_header.dart';
import '../widgets/property_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              const BalanceHeader(),
              Expanded(
                child: PropertyList(
                  onPassGo: () {
                    _onPassGo(context);
                  },
                ),
              ),
              const AssetsFooter(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showResetConfirmation(context),
        tooltip: 'Reset Game',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _onPassGo(BuildContext context) async {
    final cubit = context.read<GameCubit>();
    final success = await cubit.adjustCash(200);

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to collect cash'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collected \$200 for passing Go!')),
      );
    }
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Game?'),
        content: const Text(
          'This will reset your cash to \$1,500 and release all properties.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final cubit = context.read<GameCubit>();
              final success = await cubit.resetGame();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game reset!')),
                );
              } else if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to reset'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
