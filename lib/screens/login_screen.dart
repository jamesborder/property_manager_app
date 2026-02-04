import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const List<String> _allowedPlayers = [
    'Jim',
  ];

  final _nameController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorText = 'Please enter your name');
      return;
    }

    final matchedPlayer = _allowedPlayers.cast<String?>().firstWhere(
          (player) => player!.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );

    if (matchedPlayer == null) {
      setState(() => _errorText = 'Name not recognized');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      if (kDebugMode) print('[Login] Setting playerIdProvider for $matchedPlayer');

      // Set player ID — triggers gameNotifierProvider.build()
      ref.read(playerIdProvider.notifier).state = matchedPlayer;

      // Await the game state load
      if (kDebugMode) print('[Login] Awaiting game state...');
      await ref.read(gameNotifierProvider.future);

      if (!mounted) return;

      // Save player for auto-login
      if (kDebugMode) print('[Login] Saving player...');
      await AuthService.savePlayer(matchedPlayer);

      if (!mounted) return;

      if (kDebugMode) print('[Login] Navigating to home...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e, stack) {
      if (kDebugMode) {
        print('[Login] Error: $e');
        print(stack);
      }
      // Reset player ID on failure
      ref.read(playerIdProvider.notifier).state = null;
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = 'Failed to load game: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Property Manager',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Name input
              TextField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Your first name',
                  border: const OutlineInputBorder(),
                  errorText: _errorText,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
                onSubmitted: (_) => _handleSubmit(),
              ),
              const SizedBox(height: 24),

              // Submit button
              FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Start Playing'),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MVP Version 0.2.0',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      'NestJS:PostgresSQL:Flutter:Riverpod',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
