import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/property_data.dart';
import '../models/property.dart';
import '../rules/game_rules.dart';
import '../services/api_service.dart';
import 'game_state.dart';
import 'providers.dart';

class GameNotifier extends AsyncNotifier<GameState> {
  late final ApiService _api;
  late final List<Property> _properties;

  @override
  Future<GameState> build() async {
    _api = ApiService();
    _properties = createInitialProperties();

    final playerId = ref.watch(playerIdProvider);
    if (playerId == null) {
      throw StateError('No player ID set');
    }

    final response = await _api.getGameState(playerId);
    _applyState(response);

    return GameState(
      playerId: playerId,
      cash: response.cash,
      properties: _properties,
    );
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
      GameRules.canPurchase(property, state.requireValue.cash);

  bool canBuildHouse(Property property) =>
      GameRules.canBuildHouse(property, _properties, state.requireValue.cash);

  bool canBuildHotel(Property property) =>
      GameRules.canBuildHotel(property, _properties, state.requireValue.cash);

  bool canSellImprovement(Property property) =>
      GameRules.canSellImprovement(property, _properties);

  bool canMortgage(Property property) =>
      GameRules.canMortgage(property, _properties);

  bool canUnmortgage(Property property) =>
      GameRules.canUnmortgage(property, state.requireValue.cash);

  bool canReleaseProperty(Property property) =>
      GameRules.canReleaseProperty(property, _properties);

  // ─────────────────────────────────────────────────────────────────────────────
  // API ACTIONS
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> adjustCash(int amount) =>
      _callApi(() => _api.adjustCash(state.requireValue.playerId, amount));

  Future<bool> purchaseProperty(Property property) =>
      _callApi(() => _api.purchaseProperty(state.requireValue.playerId, property.id));

  Future<bool> buildHouse(Property property) =>
      _callApi(() => _api.buildHouse(state.requireValue.playerId, property.id));

  Future<bool> buildHotel(Property property) =>
      _callApi(() => _api.buildHotel(state.requireValue.playerId, property.id));

  Future<bool> sellImprovement(Property property) =>
      _callApi(() => _api.sellImprovement(state.requireValue.playerId, property.id));

  Future<bool> mortgage(Property property) =>
      _callApi(() => _api.mortgage(state.requireValue.playerId, property.id));

  Future<bool> unmortgage(Property property) =>
      _callApi(() => _api.unmortgage(state.requireValue.playerId, property.id));

  Future<bool> releaseProperty(Property property) =>
      _callApi(() => _api.releaseProperty(state.requireValue.playerId, property.id));

  Future<bool> resetGame() =>
      _callApi(() => _api.resetGame(state.requireValue.playerId));

  // ─────────────────────────────────────────────────────────────────────────────
  // INTERNAL HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Call API and apply returned state. Returns true on success.
  ///
  /// Preserves previous state during API calls — no loading flash for actions.
  /// Only build() uses the full AsyncLoading state.
  Future<bool> _callApi(
    Future<GameStateResponse> Function() apiCall,
  ) async {
    final previous = state.valueOrNull;

    try {
      final response = await apiCall();
      _applyState(response);
      state = AsyncData(GameState(
        playerId: previous?.playerId ?? response.playerId,
        cash: response.cash,
        properties: _properties,
      ));
      return true;
    } on ApiException catch (e, stack) {
      state = AsyncError(e.message, stack);
      if (previous != null) {
        state = AsyncData(previous);
      }
      return false;
    } catch (e, stack) {
      state = AsyncError('Connection error: $e', stack);
      if (previous != null) {
        state = AsyncData(previous);
      }
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
