import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_dependencies.dart';
import '../../auth/models/auth_launch_destination.dart';
import '../../pets/data/pet_catalog_provider.dart';
import '../data/initial_invite_link_reader.dart';
import '../models/app_startup_destination.dart';

const _minimumSplashDuration = Duration(seconds: 2);

final initialInviteLinkReaderProvider =
    Provider<InitialInviteLinkReader>((ref) {
  return const InitialInviteLinkReader();
});

final appStartupProvider = FutureProvider<AppStartupDestination>((ref) async {
  final launchFuture = ref.refresh(appLaunchProvider.future);
  final initialInviteTokenFuture =
      ref.read(initialInviteLinkReaderProvider).readToken();
  final minimumSplashFuture = Future<void>.delayed(_minimumSplashDuration);

  final launch = await launchFuture;
  final initialInviteToken = await initialInviteTokenFuture;

  if (launch == AppLaunchDestination.authenticated) {
    await ref.read(petCatalogProvider.future);
  }

  await minimumSplashFuture;

  return switch (launch) {
    AppLaunchDestination.authenticated =>
      initialInviteToken != null && initialInviteToken.isNotEmpty
          ? AppStartupDestination.authenticatedWithInvite(initialInviteToken)
          : const AppStartupDestination.authenticated(),
    AppLaunchDestination.unauthenticated =>
      initialInviteToken != null && initialInviteToken.isNotEmpty
          ? AppStartupDestination.unauthenticatedWithInvite(initialInviteToken)
          : const AppStartupDestination.unauthenticated(),
  };
});
