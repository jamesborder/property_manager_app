import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HSOA-Opoly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const _AppStartup(),
    );
  }
}

/// Handles async startup: checks for saved player, routes accordingly
class _AppStartup extends ConsumerStatefulWidget {
  const _AppStartup();

  @override
  ConsumerState<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends ConsumerState<_AppStartup> {
  @override
  void initState() {
    super.initState();
    _checkSavedPlayer();
  }

  Future<void> _checkSavedPlayer() async {
    try {
      final savedPlayer = await AuthService.getSavedPlayer();

      if (!mounted) return;

      if (savedPlayer == null) {
        _navigateToLogin();
        return;
      }

      // Set player ID — triggers gameNotifierProvider.build()
      ref.read(playerIdProvider.notifier).state = savedPlayer;

      // Await the game state load
      await ref.read(gameNotifierProvider.future);

      if (!mounted) return;
      _navigateToHome();
    } catch (e) {
      // API error or any startup failure — clear saved player, go to login
      await AuthService.clearPlayer();
      if (mounted) _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
