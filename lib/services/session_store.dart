import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _key = 'autopieces_token';

  static Future<String?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getString(_key);
      return t == null || t.isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, token);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
