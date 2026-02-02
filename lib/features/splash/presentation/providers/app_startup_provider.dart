import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';

final appStartupProvider = FutureProvider<AppLaunchDestination>((ref) async {
  await ref.read(catalogSyncProvider.future);
  final launch = await ref.refresh(appLaunchProvider.future);
  return launch;
});
