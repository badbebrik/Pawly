import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/log_models.dart';
import '../models/log_refs.dart';
import 'analytics_controller.dart';
import 'logs_controller.dart';
import 'logs_dependencies.dart';

final petLogDetailsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetLogDetailsController, LogDetails, PetLogRef>(
  PetLogDetailsController.new,
);

class PetLogDetailsController extends AsyncNotifier<LogDetails> {
  PetLogDetailsController(this._refValue);

  final PetLogRef _refValue;

  @override
  Future<LogDetails> build() {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<void> delete({required int rowVersion}) async {
    await ref.read(logsRepositoryProvider).deleteLog(
          _refValue.petId,
          _refValue.logId,
          rowVersion: rowVersion,
        );
    ref.invalidate(petLogsControllerProvider(_refValue.petId));
    ref.invalidate(petAnalyticsMetricsProvider);
    ref.invalidate(petMetricSeriesProvider);
    ref.invalidate(petLogDetailsControllerProvider(_refValue));
  }

  Future<LogDetails> _load() async {
    return ref
        .read(logsRepositoryProvider)
        .getLog(_refValue.petId, _refValue.logId);
  }
}
