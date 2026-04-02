import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../catalog/presentation/providers/pet_dictionaries_providers.dart';

final appStartupProvider = FutureProvider<AppLaunchDestination>((ref) async {
  final launch = await ref.refresh(appLaunchProvider.future);

  if (launch == AppLaunchDestination.authenticated) {
    await ref.read(petDictionariesSyncProvider.future);
  }

  return launch;
});
