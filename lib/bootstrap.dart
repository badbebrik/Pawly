import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/services/push_notifications_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  if (_shouldInitializeFirebase()) {
    await ensureFirebaseInitialized();
  }
  runApp(const ProviderScope(child: PawlyApp()));
}

bool _shouldInitializeFirebase() {
  if (kIsWeb) {
    return false;
  }

  return defaultTargetPlatform == TargetPlatform.android;
}
