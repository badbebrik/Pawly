import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/attachments/data/attachment_input.dart';
import '../models/log_form.dart';
import '../states/log_create_state.dart';
import 'analytics_controller.dart';
import 'logs_controller.dart';
import 'logs_dependencies.dart';

final logCreateControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LogCreateController, LogCreateState, String>(
  LogCreateController.new,
);

class LogCreateController extends AsyncNotifier<LogCreateState> {
  LogCreateController(this._petId);

  final String _petId;

  @override
  Future<LogCreateState> build() async {
    return LogCreateState.initial();
  }

  Future<bool> submit({
    required LogForm form,
    required List<AttachmentInput> attachments,
  }) async {
    final current = state.asData?.value ?? LogCreateState.initial();
    if (current.isSubmitting) {
      return false;
    }

    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      await ref.read(logsRepositoryProvider).createLog(
            _petId,
            form: form,
            attachments: attachments,
          );

      ref.invalidate(petLogsControllerProvider(_petId));
      ref.invalidate(petAnalyticsMetricsProvider);
      ref.invalidate(petMetricSeriesProvider);
      state = AsyncData(current.copyWith(isSubmitting: false));
      return true;
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }
}
