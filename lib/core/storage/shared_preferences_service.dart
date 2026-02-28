import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String localeKey = 'user_locale';
  static const String timeZoneKey = 'user_time_zone';

  Future<void> saveLocale(String locale) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(localeKey, locale);
  }

  Future<String?> getLocale() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(localeKey);
  }

  Future<void> saveTimeZone(String timeZone) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(timeZoneKey, timeZone);
  }

  Future<String?> getTimeZone() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(timeZoneKey);
  }

  Future<void> saveProfilePreferences({
    required String locale,
    required String timeZone,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(localeKey, locale);
    await preferences.setString(timeZoneKey, timeZone);
  }

  Future<void> clearProfilePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(localeKey);
    await preferences.remove(timeZoneKey);
  }
}
