import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import 'transaction_sheet.dart';

class BalanceHeader extends ConsumerWidget {
  const BalanceHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameNotifierProvider).requireValue;
    final cash = state.cash;
    final playerName = state.playerId;

    return GestureDetector(
      onTap: () => _showTransactionSheet(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Player name and cash
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          playerName,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showLogoutConfirmation(context, ref),
                          child: Icon(
                            Icons.logout,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$$cash',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),

              // Wallet icon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.wallet,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const TransactionSheet(),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch Player?'),
        content: const Text(
          'This will take you back to the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await AuthService.clearPlayer();
              ref.read(playerIdProvider.notifier).state = null;
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}
