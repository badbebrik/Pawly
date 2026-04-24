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
    final timeZone = await _readTimeZone();

    return DevicePreferences(
      locale: 'ru',
      timeZone: timeZone,
    );
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
