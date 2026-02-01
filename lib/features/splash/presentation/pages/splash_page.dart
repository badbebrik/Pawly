import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/app_startup_provider.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AppLaunchDestination>>(appStartupProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (destination) {
          if (destination == AppLaunchDestination.authenticated) {
            context.go(AppRoutes.home);
          } else {
            context.go(AppRoutes.login);
          }
        },
      );
    });

    final startupState = ref.watch(appStartupProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(PawlyRadius.xl),
                    boxShadow: PawlyElevation.soft(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Icon(
                    Icons.pets_rounded,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: PawlySpacing.lg),
                Text('Pawly',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Проверяем сессию...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: PawlySpacing.lg),
                startupState.when(
                  data: (_) => const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  loading: () => const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  error: (Object _, StackTrace __) {
                    return Column(
                      children: <Widget>[
                        Text(
                          'Ошибка при запуске приложения.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: PawlySpacing.sm),
                        PawlyButton(
                          label: 'Повторить',
                          fullWidth: false,
                          onPressed: () => ref.invalidate(appStartupProvider),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
