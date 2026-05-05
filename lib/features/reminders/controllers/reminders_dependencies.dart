import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/reminders_repository.dart';

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  final healthApiClient = ref.watch(healthApiClientProvider);
  return RemindersRepository(healthApiClient: healthApiClient);
});
