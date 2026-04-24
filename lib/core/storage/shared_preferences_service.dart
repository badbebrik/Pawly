import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String localeKey = 'user_locale';
  static const String timeZoneKey = 'user_time_zone';

  Future<void> saveTimeZone(String timeZone) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(timeZoneKey, timeZone);
  }

  Future<String?> getTimeZone() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(timeZoneKey);
  }

  Future<void> saveProfilePreferences({
    required String timeZone,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(localeKey);
    await preferences.setString(timeZoneKey, timeZone);
  }

  Future<void> clearProfilePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(localeKey);
    await preferences.remove(timeZoneKey);
  }

  Future<void> saveString(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  Future<void> remove(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }

  Future<void> writeJson(String key, Map<String, dynamic> payload) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> readJson(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return null;
  }
}
