import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../network/clients/health_api_client.dart';
import '../network/models/health_models.dart';
import '../network/session/auth_session_store.dart';
import '../storage/shared_preferences_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await ensureFirebaseInitialized();
}

Future<void> ensureFirebaseInitialized() async {
  if (!_supportsPushPlatform()) {
    return;
  }

  if (Firebase.apps.isNotEmpty) {
    return;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationPayload {
  const PushNotificationPayload({
    required this.type,
    this.occurrenceId,
    this.scheduledItemId,
    this.petId,
    this.sourceType,
  });

  final String type;
  final String? occurrenceId;
  final String? scheduledItemId;
  final String? petId;
  final String? sourceType;

  bool get isScheduledOccurrence => type == 'scheduled_occurrence';

  factory PushNotificationPayload.fromMessage(RemoteMessage message) {
    final data = message.data;
    return PushNotificationPayload(
      type: (data['type'] ?? '').toString(),
      occurrenceId: _nullableString(data['occurrence_id']),
      scheduledItemId: _nullableString(data['scheduled_item_id']),
      petId: _nullableString(data['pet_id']),
      sourceType: _nullableString(data['source_type']),
    );
  }

  static String? _nullableString(Object? value) {
    if (value == null) {
      return null;
    }
    final string = value.toString().trim();
    return string.isEmpty ? null : string;
  }
}

class PushNotificationsService {
  PushNotificationsService({
    required FirebaseMessaging messaging,
    required HealthApiClient healthApiClient,
    required SharedPreferencesService sharedPreferencesService,
    required AuthSessionStore authSessionStore,
  })  : _messaging = messaging,
        _healthApiClient = healthApiClient,
        _sharedPreferencesService = sharedPreferencesService,
        _authSessionStore = authSessionStore;

  static const String _deviceIdKey = 'push_device_id';

  final FirebaseMessaging _messaging;
  final HealthApiClient _healthApiClient;
  final SharedPreferencesService _sharedPreferencesService;
  final AuthSessionStore _authSessionStore;

  final StreamController<PushNotificationPayload> _openedMessagesController =
      StreamController<PushNotificationPayload>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;
  bool _initialized = false;
  String? _lastRegisteredToken;

  Stream<PushNotificationPayload> get openedMessages =>
      _openedMessagesController.stream;

  Future<NotificationSettings?> getNotificationSettings() async {
    if (!_supportsPushPlatform()) {
      return null;
    }

    await initialize();
    return _messaging.getNotificationSettings();
  }

  Future<void> initialize() async {
    if (!_supportsPushPlatform()) {
      _initialized = true;
      debugPrint('[push] initialize skipped: unsupported platform');
      return;
    }

    if (_initialized) {
      debugPrint('[push] initialize skipped: already initialized');
      return;
    }

    debugPrint('[push] initialize: ensure firebase');
    await ensureFirebaseInitialized();
    debugPrint('[push] initialize: firebase ready');

    debugPrint('[push] initialize: register background handler');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('[push] initialize: background handler ready');

    debugPrint('[push] initialize: subscribe onMessageOpenedApp');
    _messageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _emitOpenedMessage,
    );
    debugPrint('[push] initialize: onMessageOpenedApp subscribed');

    debugPrint('[push] initialize: subscribe onTokenRefresh');
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      await _registerTokenIfPossible(token: token, force: true);
    });
    debugPrint('[push] initialize: onTokenRefresh subscribed');

    debugPrint('[push] initialize: getInitialMessage');
    final initialMessage = await _messaging
        .getInitialMessage()
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (initialMessage != null) {
      _emitOpenedMessage(initialMessage);
    }
    debugPrint('[push] initialize: getInitialMessage done');

    _initialized = true;
    debugPrint('[push] initialize: completed');
  }

  Future<bool> requestPermissionsIfNeeded() async {
    if (!_supportsPushPlatform()) {
      debugPrint('[push] unsupported platform, skip permission request');
      return false;
    }

    final currentSettings = await _messaging.getNotificationSettings();
    debugPrint(
      '[push] current authorization status: ${currentSettings.authorizationStatus.name}',
    );

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      '[push] authorization status after request: ${settings.authorizationStatus.name}',
    );

    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized => true,
      AuthorizationStatus.provisional => true,
      _ => false,
    };
  }

  Future<void> syncTokenForCurrentSession() async {
    if (!_supportsPushPlatform()) {
      debugPrint('[push] unsupported platform, skip token sync');
      return;
    }

    debugPrint('[push] start token sync');
    await initialize();
    final authorized = await requestPermissionsIfNeeded();
    if (!authorized) {
      debugPrint('[push] notification permission not granted, skip token sync');
      return;
    }

    await _waitForApnsTokenIfNeeded();
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[push] FCM token is empty, skip backend registration');
      return;
    }

    debugPrint('[push] got FCM token, register on backend');
    await _registerTokenIfPossible(token: token);
  }

  Future<void> unregisterCurrentDevice() async {
    if (!_supportsPushPlatform()) {
      return;
    }

    final session = await _authSessionStore.read();
    if (session == null) {
      return;
    }

    final deviceId = await _getOrCreateDeviceId();
    try {
      await _healthApiClient.deletePushDevice(deviceId);
      debugPrint('[push] device unregistered: $deviceId');
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _messageOpenedAppSubscription?.cancel();
    await _openedMessagesController.close();
  }

  void _emitOpenedMessage(RemoteMessage message) {
    final payload = PushNotificationPayload.fromMessage(message);
    if (!payload.isScheduledOccurrence) {
      return;
    }
    _openedMessagesController.add(payload);
  }

  Future<void> _registerTokenIfPossible({
    required String token,
    bool force = false,
  }) async {
    final session = await _authSessionStore.read();
    if (session == null || session.accessToken.isEmpty) {
      return;
    }

    if (!force && _lastRegisteredToken == token) {
      return;
    }

    final deviceId = await _getOrCreateDeviceId();

    try {
      await _healthApiClient.registerPushDevice(
        DeviceTokenPayload(
          deviceId: deviceId,
          platform:
              defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID',
          pushToken: token,
        ),
      );
      _lastRegisteredToken = token;
      debugPrint('[push] device token registered on backend');
    } catch (error, stackTrace) {
      debugPrint('[push] failed to register device token: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _sharedPreferencesService.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final suffix = List<int>.generate(16, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    final deviceId = 'pawly-$timestamp-$suffix';
    await _sharedPreferencesService.saveString(_deviceIdKey, deviceId);
    return deviceId;
  }

  Future<void> _waitForApnsTokenIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    for (var attempt = 0; attempt < 10; attempt++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null && apnsToken.isNotEmpty) {
        debugPrint('[push] APNs token is available');
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    debugPrint('[push] APNs token is still missing after waiting');
  }
}

bool _supportsPushPlatform() {
  if (kIsWeb) {
    return false;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => true,
    TargetPlatform.iOS => true,
    _ => false,
  };
}
