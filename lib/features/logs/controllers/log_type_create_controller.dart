import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/log_type_form.dart';
import '../states/log_type_create_state.dart';
import 'logs_controller.dart';
import 'logs_dependencies.dart';

final logTypeCreateControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LogTypeCreateController, LogTypeCreateState, String>(
  LogTypeCreateController.new,
);

class LogTypeCreateController extends AsyncNotifier<LogTypeCreateState> {
  LogTypeCreateController(this._petId);

  final String _petId;

  @override
  Future<LogTypeCreateState> build() async {
    return LogTypeCreateState.initial();
  }

  Future<String?> submit(LogTypeForm form) async {
    final current = state.asData?.value ?? LogTypeCreateState.initial();
    if (current.isSubmitting) {
      return null;
    }

    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      final type = await ref.read(logsRepositoryProvider).createLogType(
            _petId,
            form: form,
          );
      ref.invalidate(petLogComposerBootstrapProvider(_petId));
      state = AsyncData(current.copyWith(isSubmitting: false));
      return type.id;
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }
}
