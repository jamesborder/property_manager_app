import 'package:flutter/foundation.dart';
import '../data/property_data.dart';
import '../models/player.dart';
import '../models/property.dart';
import '../rules/game_rules.dart';
import '../services/api_service.dart';

class GameProvider extends ChangeNotifier {
  final ApiService _api;
  final Player _player;
  final List<Property> _properties;

  bool _isLoading = false;
  String? _error;

  GameProvider({
    required String playerId,
    ApiService? apiService,
  })  : _api = apiService ?? ApiService(),
        _player = Player(id: playerId, cash: 1500),
        _properties = createInitialProperties();

  // ─────────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────────────────────────────────────

  String get playerId => _player.id;
  int get cash => _player.cash;
  List<Property> get properties => List.unmodifiable(_properties);
  List<Property> get ownedProperties =>
      _properties.where((p) => p.isOwned).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalAssets => GameRules.totalAssets(cash, _properties);

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
      GameRules.canPurchase(property, cash);

  bool canBuildHouse(Property property) =>
      GameRules.canBuildHouse(property, _properties, cash);

  bool canBuildHotel(Property property) =>
      GameRules.canBuildHotel(property, _properties, cash);

  bool canSellImprovement(Property property) =>
      GameRules.canSellImprovement(property, _properties);

  bool canMortgage(Property property) =>
      GameRules.canMortgage(property, _properties);

  bool canUnmortgage(Property property) =>
      GameRules.canUnmortgage(property, cash);

  bool canReleaseProperty(Property property) =>
      GameRules.canReleaseProperty(property, _properties);

  // ─────────────────────────────────────────────────────────────────────────────
  // API ACTIONS
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> loadGameState() async {
    await _callApi(() => _api.getGameState(playerId));
  }

  Future<bool> adjustCash(int amount) async {
    return _callApi(() => _api.adjustCash(playerId, amount));
  }

  Future<bool> purchaseProperty(Property property) async {
    return _callApi(() => _api.purchaseProperty(playerId, property.id));
  }

  Future<bool> buildHouse(Property property) async {
    return _callApi(() => _api.buildHouse(playerId, property.id));
  }

  Future<bool> buildHotel(Property property) async {
    return _callApi(() => _api.buildHotel(playerId, property.id));
  }

  Future<bool> sellImprovement(Property property) async {
    return _callApi(() => _api.sellImprovement(playerId, property.id));
  }

  Future<bool> mortgage(Property property) async {
    return _callApi(() => _api.mortgage(playerId, property.id));
  }

  Future<bool> unmortgage(Property property) async {
    return _callApi(() => _api.unmortgage(playerId, property.id));
  }

  Future<bool> releaseProperty(Property property) async {
    return _callApi(() => _api.releaseProperty(playerId, property.id));
  }

  Future<bool> resetGame() async {
    return _callApi(() => _api.resetGame(playerId));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // INTERNAL HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Call API and apply returned state
  Future<bool> _callApi(
    Future<GameStateResponse> Function() apiCall,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiCall();
      _applyState(response);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Apply API response to local state
  void _applyState(GameStateResponse response) {
    _player.cash = response.cash;

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

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
