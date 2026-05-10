import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'image_memory_pressure.dart';

class SystemSettingsLauncher {
  const SystemSettingsLauncher();

  static const MethodChannel _channel = MethodChannel(
    'com.hse.pawly/system_settings',
  );

  Future<bool> openNotificationSettings() async {
    if (kIsWeb) {
      return false;
    }

    trimDecodedImageMemory(includeLiveImages: true);

    if (Platform.isAndroid) {
      return await _invokeAndroid('openNotificationSettings');
    }

    if (Platform.isIOS) {
      return launchUrl(
        Uri.parse('app-settings:'),
        mode: LaunchMode.externalApplication,
      );
    }

    return false;
  }

  Future<bool> _invokeAndroid(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
