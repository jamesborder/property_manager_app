import '../models/property.dart';
import '../rules/game_rules.dart';

/// Immutable game state — replaces mutable fields on GameProvider.
///
/// Property objects remain mutable (Option A from strategy doc).
/// The _applyState method mutates them in place, then we create a new
/// GameState with a fresh list reference so Riverpod detects the change.
class GameState {
  final String playerId;
  final int cash;
  final List<Property> properties;

  const GameState({
    required this.playerId,
    required this.cash,
    required this.properties,
  });

  List<Property> get ownedProperties =>
      properties.where((p) => p.isOwned).toList();

  int get totalAssets => GameRules.totalAssets(cash, properties);

  GameState copyWith({
    int? cash,
    List<Property>? properties,
  }) {
    return GameState(
      playerId: playerId,
      cash: cash ?? this.cash,
      properties: properties ?? this.properties,
    );
  }
}
