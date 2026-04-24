import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/deep_links/deep_link_navigation_state.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../providers/app_startup_provider.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(pendingDeepLinkTargetProvider, (previous, next) {
      if (next == null || next.isEmpty) {
        return;
      }
      debugPrint(
        '[PawlyDeepLink][splash] pending target received=$next '
        'matched=${GoRouterState.of(context).matchedLocation}',
      );
      final destination = ref.read(appStartupProvider).asData?.value;
      if (destination != null) {
        _navigateFromSplash(context, ref, destination);
      }
    });

    ref.listen<AsyncValue<AppStartupDestination>>(appStartupProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (destination) {
          _navigateFromSplash(context, ref, destination);
        },
      );
    });

    final startupState = ref.watch(appStartupProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PawlySpacing.lg,
              vertical: PawlySpacing.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Pawly',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: PawlySpacing.xl),
                    Center(
                      child: Transform.translate(
                        offset: const Offset(-10, 0),
                        child: SizedBox(
                          width: 260,
                          height: 260,
                          child: Lottie.asset(
                            'assets/animations/moody_dog.json',
                            fit: BoxFit.contain,
                            repeat: true,
                            frameRate: FrameRate.max,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.pets_rounded,
                                size: 104,
                                color: Theme.of(context).colorScheme.primary,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xl),
                    _StartupStatus(
                      startupState: startupState,
                      onRetry: () => ref.invalidate(appStartupProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _navigateFromSplash(
  BuildContext context,
  WidgetRef ref,
  AppStartupDestination destination,
) {
  final pendingDeepLinkTarget = ref.read(pendingDeepLinkTargetProvider);
  debugPrint(
    '[PawlyDeepLink][splash] destination=${destination.kind} '
    'pendingTarget=$pendingDeepLinkTarget '
    'matched=${GoRouterState.of(context).matchedLocation}',
  );
  if (!context.mounted ||
      GoRouterState.of(context).matchedLocation != AppRoutes.splash) {
    debugPrint('[PawlyDeepLink][splash] skip: not on splash');
    return;
  }
  final target = _resolveInviteTarget(
    pendingDeepLinkTarget: pendingDeepLinkTarget,
    inviteToken: destination.inviteToken,
  );
  final router = GoRouter.of(context);
  switch (destination.kind) {
    case AppStartupDestinationKind.invitePreview:
      debugPrint('[PawlyDeepLink][splash] go invitePreview target=$target');
      if (target != null) {
        router.go(target);
      } else {
        router.go(AppRoutes.pets);
      }
    case AppStartupDestinationKind.authenticated:
      debugPrint('[PawlyDeepLink][splash] go home');
      if (target != null) {
        ref.read(pendingDeepLinkTargetProvider.notifier).clear();
      }
      router.go(AppRoutes.home);
      if (target != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint(
            '[PawlyDeepLink][splash] push invitePreview target=$target',
          );
          unawaited(router.push(target));
        });
      }
    case AppStartupDestinationKind.unauthenticated:
      if (target != null) {
        final loginTarget = Uri(
          path: AppRoutes.login,
          queryParameters: <String, String>{'redirect': target},
        ).toString();
        debugPrint('[PawlyDeepLink][splash] go login redirect=$target');
        router.go(loginTarget);
        ref.read(pendingDeepLinkTargetProvider.notifier).clear();
      } else {
        debugPrint('[PawlyDeepLink][splash] go login');
        router.go(AppRoutes.login);
      }
  }
}

String? _resolveInviteTarget({
  required String? pendingDeepLinkTarget,
  required String? inviteToken,
}) {
  if (pendingDeepLinkTarget != null && pendingDeepLinkTarget.isNotEmpty) {
    return pendingDeepLinkTarget;
  }
  if (inviteToken == null || inviteToken.isEmpty) {
    return null;
  }
  return Uri(
    path: AppRoutes.aclInvitePreview,
    queryParameters: <String, String>{'token': inviteToken},
  ).toString();
}

class _StartupStatus extends StatelessWidget {
  const _StartupStatus({required this.startupState, required this.onRetry});

  final AsyncValue<AppStartupDestination> startupState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return startupState.when(
      data: (_) => const _SessionCheckStatus(),
      loading: () => const _SessionCheckStatus(),
      error: (Object _, StackTrace __) {
        return Column(
          children: <Widget>[
            Text(
              'Не удалось запустить приложение',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: PawlySpacing.md),
            PawlyButton(
              label: 'Повторить',
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        );
      },
    );
  }
}

class _SessionCheckStatus extends StatelessWidget {
  const _SessionCheckStatus();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        Text(
          'Проверяем сессию...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
