import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_notifier.dart';
import 'game_state.dart';

/// Player ID — set on login, null when logged out.
final playerIdProvider = StateProvider<String?>((ref) => null);

/// Main game state — auto-loads when playerIdProvider is set.
final gameNotifierProvider =
    AsyncNotifierProvider<GameNotifier, GameState>(GameNotifier.new);
