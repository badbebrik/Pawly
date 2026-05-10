import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/deep_links/deep_link_navigation_state.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../controllers/app_startup_controller.dart';
import '../../models/app_startup_destination.dart';
import '../widgets/splash_status_view.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(pendingDeepLinkTargetProvider, (previous, next) {
      if (next == null || next.isEmpty) {
        return;
      }
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
                    SplashStatusView(
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
  if (!context.mounted ||
      GoRouterState.of(context).matchedLocation != AppRoutes.splash) {
    return;
  }
  final target = _resolveInviteTarget(
    pendingDeepLinkTarget: pendingDeepLinkTarget,
    inviteToken: destination.inviteToken,
  );
  final router = GoRouter.of(context);
  switch (destination.kind) {
    case AppStartupDestinationKind.authenticated:
      if (target != null) {
        ref.read(pendingDeepLinkTargetProvider.notifier).clear();
      }
      router.go(AppRoutes.home);
      if (target != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_pushDeepLinkTarget(router, target));
        });
      }
    case AppStartupDestinationKind.unauthenticated:
      if (target != null) {
        final loginTarget = Uri(
          path: AppRoutes.login,
          queryParameters: <String, String>{'redirect': target},
        ).toString();
        router.go(loginTarget);
        ref.read(pendingDeepLinkTargetProvider.notifier).clear();
      } else {
        router.go(AppRoutes.login);
      }
  }
}

Future<void> _pushDeepLinkTarget(GoRouter router, String target) async {
  try {
    await router.push<void>(target);
  } catch (_) {}
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
