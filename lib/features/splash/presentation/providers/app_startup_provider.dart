import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

final appStartupProvider = FutureProvider<AppLaunchDestination>((ref) async {
  final launch = await ref.refresh(appLaunchProvider.future);

  await Future<void>.delayed(const Duration(milliseconds: 900));

  return launch;
});
