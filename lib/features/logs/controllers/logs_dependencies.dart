import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/logs_repository.dart';

final logsRepositoryProvider = Provider<LogsRepository>((ref) {
  final healthApiClient = ref.watch(healthApiClientProvider);
  return LogsRepository(healthApiClient: healthApiClient);
});
