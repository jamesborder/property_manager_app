import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple local storage for persisting the logged-in player
class AuthService {
  static const _playerKey = 'saved_player_name';

  /// Get saved player name (null if not logged in or unavailable)
  static Future<String?> getSavedPlayer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_playerKey);
    } catch (e) {
      if (kDebugMode) print('[AuthService] getSavedPlayer failed: $e');
      return null;
    }
  }

  /// Save player name for auto-login
  static Future<void> savePlayer(String playerName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_playerKey, playerName);
    } catch (e) {
      if (kDebugMode) print('[AuthService] savePlayer failed: $e');
      // Silently fail - app still works, just won't remember
    }
  }

  /// Clear saved player (logout)
  static Future<void> clearPlayer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_playerKey);
    } catch (e) {
      if (kDebugMode) print('[AuthService] clearPlayer failed: $e');
    }
  }
}
