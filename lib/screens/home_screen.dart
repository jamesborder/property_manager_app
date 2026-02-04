import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/assets_footer.dart';
import '../widgets/balance_header.dart';
import '../widgets/property_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    _onPassGo(context, ref);
                  },
                ),
              ),
              const AssetsFooter(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showResetConfirmation(context, ref),
        tooltip: 'Reset Game',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _onPassGo(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(gameNotifierProvider.notifier);
    final success = await notifier.adjustCash(200);

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

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
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
              final notifier = ref.read(gameNotifierProvider.notifier);
              final success = await notifier.resetGame();
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
