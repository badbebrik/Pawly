import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/attachments/data/attachment_input.dart';
import '../models/log_form.dart';
import '../models/log_refs.dart';
import '../states/log_edit_state.dart';
import 'analytics_controller.dart';
import 'log_details_controller.dart';
import 'logs_controller.dart';
import 'logs_dependencies.dart';

final logEditControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LogEditController, LogEditState, PetLogRef>(
  LogEditController.new,
);

class LogEditController extends AsyncNotifier<LogEditState> {
  LogEditController(this._logRef);

  final PetLogRef _logRef;

  @override
  Future<LogEditState> build() async {
    return LogEditState.initial();
  }

  Future<bool> submit({
    required LogForm form,
    required List<AttachmentInput> attachments,
    required int rowVersion,
  }) async {
    final current = state.asData?.value ?? LogEditState.initial();
    if (current.isSubmitting) {
      return false;
    }

    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      await ref.read(logsRepositoryProvider).updateLog(
            _logRef.petId,
            _logRef.logId,
            form: form,
            attachments: attachments,
            rowVersion: rowVersion,
          );

      ref.invalidate(petLogsControllerProvider(_logRef.petId));
      ref.invalidate(petAnalyticsMetricsProvider);
      ref.invalidate(petMetricSeriesProvider);
      ref.invalidate(petLogDetailsControllerProvider(_logRef));
      state = AsyncData(current.copyWith(isSubmitting: false));
      return true;
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }
}
