import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/game_cubit.dart';
import 'cubit/game_state.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    BlocProvider(
      create: (_) => GameCubit(),
      child: const MyApp(),
    ),
  );
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

      // Load game state for saved player
      final cubit = context.read<GameCubit>();
      await cubit.loadGame(savedPlayer);

      if (!mounted) return;

      if (cubit.state is GameLoaded) {
        _navigateToHome();
      } else {
        await AuthService.clearPlayer();
        if (mounted) _navigateToLogin();
      }
    } catch (e) {
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
