import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/property_data.dart';
import '../models/property.dart';
import '../rules/game_rules.dart';
import '../services/api_service.dart';
import 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final ApiService _api;
  final List<Property> _properties;

  GameCubit({ApiService? api})
      : _api = api ?? ApiService(),
        _properties = createInitialProperties(),
        super(const GameInitial());

  /// Load game state for a player. Called from login/startup.
  Future<void> loadGame(String playerId) async {
    emit(const GameLoading());

    try {
      final response = await _api.getGameState(playerId);
      _applyState(response);
      emit(GameLoaded(
        playerId: playerId,
        cash: response.cash,
        properties: _properties,
      ));
    } on ApiException catch (e) {
      emit(GameError(e.message));
    } catch (e) {
      emit(GameError('Connection error: $e'));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // GAME RULES DELEGATES
  // ─────────────────────────────────────────────────────────────────────────────

  int getActualRentValue(Property property) =>
      GameRules.getActualRentValue(property, _properties);

  String getRentDisplayString(Property property) =>
      GameRules.getRentDisplayString(property, _properties);

  int getRailroadRent(Property property) =>
      GameRules.getRailroadRent(property, _properties);

  int getOwnedRailroadCount() =>
      GameRules.getOwnedRailroadCount(_properties);

  int getOwnedUtilityCount() =>
      GameRules.getOwnedUtilityCount(_properties);

  int getUtilityMultiplier() =>
      GameRules.getUtilityMultiplier(_properties);

  bool hasColorGroupBonus(Property property) =>
      GameRules.hasColorGroupBonus(property, _properties);

  bool canPurchase(Property property) =>
      GameRules.canPurchase(property, _requireLoaded.cash);

  bool canBuildHouse(Property property) =>
      GameRules.canBuildHouse(property, _properties, _requireLoaded.cash);

  bool canBuildHotel(Property property) =>
      GameRules.canBuildHotel(property, _properties, _requireLoaded.cash);

  bool canSellImprovement(Property property) =>
      GameRules.canSellImprovement(property, _properties);

  bool canMortgage(Property property) =>
      GameRules.canMortgage(property, _properties);

  bool canUnmortgage(Property property) =>
      GameRules.canUnmortgage(property, _requireLoaded.cash);

  bool canReleaseProperty(Property property) =>
      GameRules.canReleaseProperty(property, _properties);

  // ─────────────────────────────────────────────────────────────────────────────
  // API ACTIONS
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> adjustCash(int amount) =>
      _callApi(() => _api.adjustCash(_requireLoaded.playerId, amount));

  Future<bool> purchaseProperty(Property property) =>
      _callApi(() => _api.purchaseProperty(_requireLoaded.playerId, property.id));

  Future<bool> buildHouse(Property property) =>
      _callApi(() => _api.buildHouse(_requireLoaded.playerId, property.id));

  Future<bool> buildHotel(Property property) =>
      _callApi(() => _api.buildHotel(_requireLoaded.playerId, property.id));

  Future<bool> sellImprovement(Property property) =>
      _callApi(() => _api.sellImprovement(_requireLoaded.playerId, property.id));

  Future<bool> mortgage(Property property) =>
      _callApi(() => _api.mortgage(_requireLoaded.playerId, property.id));

  Future<bool> unmortgage(Property property) =>
      _callApi(() => _api.unmortgage(_requireLoaded.playerId, property.id));

  Future<bool> releaseProperty(Property property) =>
      _callApi(() => _api.releaseProperty(_requireLoaded.playerId, property.id));

  Future<bool> resetGame() =>
      _callApi(() => _api.resetGame(_requireLoaded.playerId));

  // ─────────────────────────────────────────────────────────────────────────────
  // INTERNAL HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Convenience getter — asserts state is loaded.
  /// Used by action methods that should only be called when data exists.
  GameLoaded get _requireLoaded => state as GameLoaded;

  /// Call API and apply returned state. Returns true on success.
  ///
  /// No loading emission for actions — previous state stays visible.
  /// Only loadGame() emits GameLoading.
  Future<bool> _callApi(
    Future<GameStateResponse> Function() apiCall,
  ) async {
    final previous = state;
    if (previous is! GameLoaded) return false;

    try {
      final response = await apiCall();
      _applyState(response);
      emit(GameLoaded(
        playerId: previous.playerId,
        cash: response.cash,
        properties: _properties,
      ));
      return true;
    } on ApiException catch (e) {
      emit(GameError(e.message));
      emit(previous);
      return false;
    } catch (e) {
      emit(GameError('Connection error: $e'));
      emit(previous);
      return false;
    }
  }

  /// Apply API response to local property state.
  void _applyState(GameStateResponse response) {
    final ownedMap = <String, OwnedPropertyResponse>{};
    for (final owned in response.properties) {
      ownedMap[owned.propertyId] = owned;
    }

    for (final property in _properties) {
      final owned = ownedMap[property.id];
      if (owned != null) {
        property.isOwned = true;
        property.houseCount = owned.houseCount;
        property.isMortgaged = owned.isMortgaged;
      } else {
        property.isOwned = false;
        property.houseCount = 0;
        property.isMortgaged = false;
      }
    }
  }
}
