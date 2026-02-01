import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/auth_repository.dart';

enum AppLaunchDestination { authenticated, unauthenticated }

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authApiClient = ref.watch(authApiClientProvider);
  final sessionStore = ref.watch(authSessionStoreProvider);

  return AuthRepository(
    authApiClient: authApiClient,
    authSessionStore: sessionStore,
  );
});

final appLaunchProvider = FutureProvider<AppLaunchDestination>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final restored = await authRepository.tryRestoreSession();

  if (restored) {
    return AppLaunchDestination.authenticated;
  }

  return AppLaunchDestination.unauthenticated;
});
