import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/services/push_notifications_service.dart';

const int _maxImageCacheEntries = 60;
const int _maxImageCacheBytes = 48 * 1024 * 1024;

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureImageCache();
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

  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
}

void _configureImageCache() {
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = _maxImageCacheEntries;
  imageCache.maximumSizeBytes = _maxImageCacheBytes;
}
