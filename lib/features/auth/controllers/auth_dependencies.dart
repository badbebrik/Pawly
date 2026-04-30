import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/auth_repository.dart';
import '../models/auth_launch_destination.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authApiClient = ref.watch(authApiClientProvider);
  final sessionStore = ref.watch(authSessionStoreProvider);
  final devicePreferencesService = ref.watch(devicePreferencesServiceProvider);
  final googleSignInService = ref.watch(googleSignInServiceProvider);
  final pushNotificationsService = ref.watch(pushNotificationsServiceProvider);
  final sharedPreferencesService = ref.watch(sharedPreferencesServiceProvider);

  return AuthRepository(
    authApiClient: authApiClient,
    authSessionStore: sessionStore,
    devicePreferencesService: devicePreferencesService,
    googleSignInService: googleSignInService,
    pushNotificationsService: pushNotificationsService,
    sharedPreferencesService: sharedPreferencesService,
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

final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final sessionStore = ref.watch(authSessionStoreProvider);
  final session = await sessionStore.read();
  return session?.userId;
});
