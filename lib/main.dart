import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/game_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Manager',
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
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();

}

class _AppStartupState extends State<_AppStartup> {
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

      // Auto-login: load game state
      final provider = GameProvider(playerId: savedPlayer);
      await provider.loadGameState();

      if (!mounted) return;

      if (provider.error != null) {
        // API error - clear saved player and go to login
        await AuthService.clearPlayer();
        _navigateToLogin();
        return;
      }

      _navigateToHome(provider);
    } catch (e) {
      // Any error during startup - just go to login
      if (mounted) _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigateToHome(GameProvider provider) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const HomeScreen(),
        ),
      ),
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
