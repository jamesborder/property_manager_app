import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
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

    final provider = context.read<GameProvider>();
    final success = await provider.adjustCash(200);

    if (!success) {

      /// Shouldn't happen, but just in case
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to collect cash'),
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
              final provider = context.read<GameProvider>();
              final success = await provider.resetGame();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game reset!')),
                );
              } else if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Failed to reset'),
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
