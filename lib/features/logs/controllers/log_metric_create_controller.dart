import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/log_metric_form.dart';
import '../states/log_metric_create_state.dart';
import 'logs_controller.dart';
import 'logs_dependencies.dart';

final logMetricCreateControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LogMetricCreateController, LogMetricCreateState, String>(
  LogMetricCreateController.new,
);

class LogMetricCreateController extends AsyncNotifier<LogMetricCreateState> {
  LogMetricCreateController(this._petId);

  final String _petId;

  @override
  Future<LogMetricCreateState> build() async {
    return LogMetricCreateState.initial();
  }

  Future<String?> submit(LogMetricForm form) async {
    final current = state.asData?.value ?? LogMetricCreateState.initial();
    if (current.isSubmitting) {
      return null;
    }

    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      final metric = await ref.read(logsRepositoryProvider).createMetric(
            _petId,
            form: form,
          );
      ref.invalidate(petLogComposerBootstrapProvider(_petId));
      state = AsyncData(current.copyWith(isSubmitting: false));
      return metric.id;
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }
}
