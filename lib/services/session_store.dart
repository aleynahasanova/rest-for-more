import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which user is logged in, on this phone.
///
/// Only the user id is saved, never the password. When the app opens again,
/// the user is loaded from the database with this id, so nobody has to log in
/// again. Logging out removes the id.
class SessionStore {
  static const String _key = 'logged_in_user_id';

  Future<void> save(String userId) async {
    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(_key, userId);
    } catch (error) {
      debugPrint('Could not remember the login: $error');
    }
  }

  /// The id of the user who was logged in, or null when nobody was.
  Future<String?> read() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      return preferences.getString(_key);
    } catch (error) {
      debugPrint('Could not read the saved login: $error');

      return null;
    }
  }

  Future<void> clear() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.remove(_key);
    } catch (error) {
      debugPrint('Could not forget the login: $error');
    }
  }
}
