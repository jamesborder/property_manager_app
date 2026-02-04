import '../models/property.dart';
import '../rules/game_rules.dart';

/// Sealed game state — replaces GameState + AsyncValue from Riverpod.
///
/// Pattern matching with `switch` is exhaustive — compiler catches missing cases.
/// No nullable fields — GameLoaded has required playerId, cash, properties.
sealed class GameState {
  const GameState();
}

/// No player loaded yet
class GameInitial extends GameState {
  const GameInitial();
}

/// Loading game state from API
class GameLoading extends GameState {
  const GameLoading();
}

/// Game state loaded successfully
class GameLoaded extends GameState {
  final String playerId;
  final int cash;
  final List<Property> properties;

  const GameLoaded({
    required this.playerId,
    required this.cash,
    required this.properties,
  });

  List<Property> get ownedProperties =>
      properties.where((p) => p.isOwned).toList();

  int get totalAssets => GameRules.totalAssets(cash, properties);

  GameLoaded copyWith({
    int? cash,
    List<Property>? properties,
  }) {
    return GameLoaded(
      playerId: playerId,
      cash: cash ?? this.cash,
      properties: properties ?? this.properties,
    );
  }
}

/// Error loading or performing action
class GameError extends GameState {
  final String message;
  const GameError(this.message);
}
