import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';

final appStartupProvider = FutureProvider<AppLaunchDestination>((ref) async {
  final launch = await ref.refresh(appLaunchProvider.future);

  if (launch == AppLaunchDestination.authenticated) {
    await ref.read(catalogSyncProvider.future);
  }

  return launch;
});
