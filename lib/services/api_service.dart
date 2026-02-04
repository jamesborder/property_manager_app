import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Response from the API containing game state
class GameStateResponse {
  final String playerId;
  final int cash;
  final List<OwnedPropertyResponse> properties;

  GameStateResponse({
    required this.playerId,
    required this.cash,
    required this.properties,
  });

  factory GameStateResponse.fromJson(Map<String, dynamic> json) {
    return GameStateResponse(
      playerId: json['playerId'] as String,
      cash: json['cash'] as int,
      properties: (json['properties'] as List)
          .map((p) => OwnedPropertyResponse.fromJson(p))
          .toList(),
    );
  }
}

class OwnedPropertyResponse {
  final String propertyId;
  final int houseCount;
  final bool isMortgaged;

  OwnedPropertyResponse({
    required this.propertyId,
    required this.houseCount,
    required this.isMortgaged,
  });

  factory OwnedPropertyResponse.fromJson(Map<String, dynamic> json) {
    return OwnedPropertyResponse(
      propertyId: json['propertyId'] as String,
      houseCount: json['houseCount'] as int,
      isMortgaged: json['isMortgaged'] as bool,
    );
  }
}

/// API error with message from server
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Service for communicating with the HSOA-Opoly API
class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  // ─────────────────────────────────────────────────────────────────────────────
  // GAME STATE
  // ─────────────────────────────────────────────────────────────────────────────

  /// Get current game state for player (creates player if new)
  Future<GameStateResponse> getGameState(String playerId) async {
    final response = await _get('/api/game/$playerId');
    return GameStateResponse.fromJson(response);
  }

  /// Reset game to starting state
  Future<GameStateResponse> resetGame(String playerId) async {
    final response = await _post('/api/game/$playerId/reset');
    return GameStateResponse.fromJson(response);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CASH
  // ─────────────────────────────────────────────────────────────────────────────

  /// Adjust cash by amount (positive = receive, negative = pay)
  Future<GameStateResponse> adjustCash(String playerId, int amount) async {
    final response = await _post(
      '/api/game/$playerId/cash',
      body: {'amount': amount},
    );
    return GameStateResponse.fromJson(response);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PROPERTY ACTIONS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Purchase a property
  Future<GameStateResponse> purchaseProperty(
    String playerId,
    String propertyId,
  ) async {
    final response = await _post(
      '/api/game/$playerId/properties/$propertyId/purchase',
    );
    return GameStateResponse.fromJson(response);
  }

  /// Build a house on a property
  Future<GameStateResponse> buildHouse(
    String playerId,
    String propertyId,
  ) async {
    final response = await _post(
      '/api/game/$playerId/properties/$propertyId/build',
    );
    return GameStateResponse.fromJson(response);
  }

  /// Build a hotel on a property
  Future<GameStateResponse> buildHotel(
    String playerId,
    String propertyId,
  ) async {
    final response = await _post(
      '/api/game/$playerId/properties/$propertyId/hotel',
    );
    return GameStateResponse.fromJson(response);
  }

  /// Sell an improvement from a property
  Future<GameStateResponse> sellImprovement(
    String playerId,
    String propertyId,
  ) async {
    final response = await _post(
      '/api/game/$playerId/properties/$propertyId/sell',
    );
    return GameStateResponse.fromJson(response);
  }

  /// Mortgage a property
  Future<GameStateResponse> mortgage(
    String playerId,
    String propertyId,
  ) async {
    final response = await _post(
      '/api/game/$playerId/properties/$propertyId/mortgage',
    );
    return GameStateResponse.fromJson(response);
  }

  /// Unmortgage a property
  Future<GameStateResponse> unmortgage(
    String playerId,
    String propertyId,
  ) async {
    final response = await _post(
      '/api/game/$playerId/properties/$propertyId/unmortgage',
    );
    return GameStateResponse.fromJson(response);
  }

  /// Release a property
  Future<GameStateResponse> releaseProperty(
    String playerId,
    String propertyId,
  ) async {
    final response = await _post(
      '/api/game/$playerId/properties/$propertyId/release',
    );
    return GameStateResponse.fromJson(response);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HTTP HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.get(uri);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] as String? ?? 'Unknown error';
    throw ApiException(message, response.statusCode);
  }
}
