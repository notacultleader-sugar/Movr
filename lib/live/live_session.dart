import 'package:shared_preferences/shared_preferences.dart';

/// Remembers this phone's current booking, so reopening the app goes
/// straight back to tracking it.
class LiveSession {
  static const _key = 'movr.activeJobId';

  static Future<String?> activeJobId() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setActiveJob(String? id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, id);
      }
    } catch (_) {}
  }
}
