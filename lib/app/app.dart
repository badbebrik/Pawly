import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'deep_links/pawly_deep_link_listener.dart';
import 'providers/theme_mode_controller.dart';
import '../core/providers/core_providers.dart';
import '../core/services/push_notifications_service.dart';
import '../design_system/design_system.dart';
import '../features/chat/controllers/chat_dependencies.dart';
import 'router/app_routes.dart';

class PawlyApp extends ConsumerWidget {
  const PawlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider).asData?.value ??
        ThemeMode.system;

    return MaterialApp.router(
      title: 'Pawly',
      debugShowCheckedModeBanner: false,
      theme: PawlyTheme.light(),
      darkTheme: PawlyTheme.dark(),
      themeMode: themeMode,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('ru'),
      ],
      routerConfig: router,
      builder: (context, child) {
        return _ChatSocketLifecycleBinding(
          child: _PushNotificationsBinding(
            child: PawlyDeepLinkListener(
              router: router,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

class _ChatSocketLifecycleBinding extends ConsumerStatefulWidget {
  const _ChatSocketLifecycleBinding({
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<_ChatSocketLifecycleBinding> createState() =>
      _ChatSocketLifecycleBindingState();
}

class _ChatSocketLifecycleBindingState
    extends ConsumerState<_ChatSocketLifecycleBinding>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resumeChatSocket();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pauseChatSocket();
        break;
    }
  }

  void _pauseChatSocket() {
    unawaited(
      ref.read(chatSocketServiceProvider).disconnect().catchError((_) {}),
    );
  }

  void _resumeChatSocket() {
    unawaited(
      ref.read(chatSocketServiceProvider).resumeIfNeeded().catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _PushNotificationsBinding extends ConsumerStatefulWidget {
  const _PushNotificationsBinding({
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<_PushNotificationsBinding> createState() =>
      _PushNotificationsBindingState();
}

class _PushNotificationsBindingState
    extends ConsumerState<_PushNotificationsBinding> {
  StreamSubscription<PushNotificationPayload>? _openedMessagesSubscription;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final service = ref.read(pushNotificationsServiceProvider);
      _openedMessagesSubscription = service.openedMessages.listen(
        _handleOpenedMessage,
      );
      await service.initialize();
      if (!mounted) {
        return;
      }
    });
  }

  @override
  void dispose() {
    _openedMessagesSubscription?.cancel();
    super.dispose();
  }

  void _handleOpenedMessage(PushNotificationPayload payload) {
    if (!payload.isScheduledOccurrence) {
      return;
    }

    final router = ref.read(appRouterProvider);
    _openScheduledOccurrence(router, payload);
  }

  void _openScheduledOccurrence(
    GoRouter router,
    PushNotificationPayload payload,
  ) {
    router.go(
      Uri(
        path: AppRoutes.calendar,
        queryParameters: <String, String>{
          if (payload.petId != null) 'pet_id': payload.petId!,
          if (payload.occurrenceId != null)
            'occurrence_id': payload.occurrenceId!,
          if (payload.scheduledItemId != null)
            'scheduled_item_id': payload.scheduledItemId!,
          if (payload.sourceType != null) 'source_type': payload.sourceType!,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
