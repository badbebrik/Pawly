import 'dart:ui';

import 'package:flutter_timezone/flutter_timezone.dart';

class DevicePreferences {
  const DevicePreferences({
    required this.locale,
    required this.timeZone,
  });

  final String locale;
  final String timeZone;
}

class DevicePreferencesService {
  Future<DevicePreferences> read() async {
    final locale = _currentLocale();
    final timeZone = await _readTimeZone();

    return DevicePreferences(
      locale: locale,
      timeZone: timeZone,
    );
  }

  String _currentLocale() {
    final locale = PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode.trim();
    if (languageCode.isEmpty) {
      return 'ru';
    }

    return languageCode.toLowerCase();
  }

  Future<String> _readTimeZone() async {
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      final identifier = timeZone.identifier;
      if (identifier.isNotEmpty) {
        return identifier;
      }
    } catch (_) {}

    return 'UTC';
  }
}
