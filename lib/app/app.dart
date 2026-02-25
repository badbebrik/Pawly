import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deep_links/pawly_deep_link_listener.dart';
import 'providers/theme_mode_controller.dart';
import '../core/providers/core_providers.dart';
import '../design_system/design_system.dart';

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
        Locale('en'),
      ],
      routerConfig: router,
      builder: (context, child) {
        return PawlyDeepLinkListener(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
