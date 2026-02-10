import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      routerConfig: router,
    );
  }
}
