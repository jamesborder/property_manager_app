import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class TransactionSheet extends StatefulWidget {
  const TransactionSheet({super.key});

  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<TransactionSheet> {
  final _amountController = TextEditingController();
  bool _isReceiving = true;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitTransaction() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() => _errorMessage = 'Enter an amount');
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a valid positive number');
      return;
    }

    final adjustedAmount = _isReceiving ? amount : -amount;
    await _processTransaction(adjustedAmount);
  }

  Future<void> _quickTransaction(int amount) async {
    await _processTransaction(amount);
  }

  Future<void> _processTransaction(int amount) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final provider = context.read<GameProvider>();
    final success = await provider.adjustCash(amount);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = provider.error ?? 'Insufficient funds';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Wallet',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Loading indicator
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),

              // Quick presets
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 18),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickButton(
                    label: 'Pass GO (+\$200)',
                    onTap: _isProcessing ? null : () => _quickTransaction(200),
                    isPositive: true,
                  ),
                  _QuickButton(
                    label: 'Bank error in your favor (+\$200)',
                    onTap: _isProcessing ? null : () => _quickTransaction(200),
                    isPositive: true,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickButton(
                    label: 'Luxury Tax (-\$100)',
                    onTap: _isProcessing ? null : () => _quickTransaction(-100),
                    isPositive: false,
                  ),
                  _QuickButton(
                    label: 'Income Tax (-\$200)',
                    onTap: _isProcessing ? null : () => _quickTransaction(-200),
                    isPositive: false,
                  ),
                  _QuickButton(
                    label: 'Jail Fine (-\$50)',
                    onTap: _isProcessing ? null : () => _quickTransaction(-50),
                    isPositive: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Custom transaction
              Text(
                'Custom Amount',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),

              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Receive')),
                  ButtonSegment(value: false, label: Text('Pay')),
                ],
                style: SegmentedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                selected: {_isReceiving},
                onSelectionChanged: _isProcessing
                    ? null
                    : (selected) {
                        setState(() {
                          _isReceiving = selected.first;
                          _errorMessage = null;
                        });
                      },
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _amountController,
                enabled: !_isProcessing,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  hintText: 'Amount',
                  errorText: _errorMessage,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                onSubmitted: (_) => _submitTransaction(),
              ),
              const SizedBox(height: 16),

              FilledButton(
                onPressed: _isProcessing ? null : _submitTransaction,
                style: FilledButton.styleFrom(
                  backgroundColor: _isReceiving ? Colors.green : Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(_isReceiving ? 'Add Funds' : 'Deduct Funds'),
                ),
              ),
              const SizedBox(height: 180),
              const Text('-'),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPositive;

  const _QuickButton({
    required this.label,
    required this.onTap,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isPositive
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
      side: BorderSide(
        color: isPositive ? Colors.green : Colors.red,
        width: 1,
      ),
    );
  }
}
