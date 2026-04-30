import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/register_step.dart';
import '../shared/mappers/auth_mappers.dart';
import '../shared/utils/auth_error_message.dart';
import '../shared/utils/auth_resend_countdown.dart';
import '../shared/utils/auth_resend_cooldown.dart';
import '../states/register_state.dart';
import 'auth_dependencies.dart';

final registerControllerProvider =
    NotifierProvider.autoDispose<RegisterController, RegisterState>(
  RegisterController.new,
);

class RegisterController extends Notifier<RegisterState> {
  final _resendCountdown = AuthResendCountdown();

  @override
  RegisterState build() {
    ref.onDispose(() {
      _resendCountdown.dispose();
    });
    return const RegisterState.initial();
  }

  void goTo(RegisterStep step) {
    state = state.copyWith(step: step, clearError: true);
  }

  void goBack() {
    final previousStep = switch (state.step) {
      RegisterStep.name => RegisterStep.name,
      RegisterStep.email => RegisterStep.name,
      RegisterStep.password => RegisterStep.email,
      RegisterStep.verification => RegisterStep.password,
    };
    goTo(previousStep);
  }

  Future<bool> submitRegistration({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final response = await ref.read(authRepositoryProvider).registerWithEmail(
            email: email.trim(),
            password: password,
            firstName: _optionalName(firstName),
            lastName: _optionalName(lastName),
          );
      final result = registerStartResultFromResponse(response);

      state = state.copyWith(
        step: RegisterStep.verification,
        isSubmitting: false,
        clearError: true,
      );
      _startResendCountdown(result.canResendInSeconds);
      return true;
    } catch (error) {
      _syncCooldownFromError(error);
      state = state.copyWith(
        isSubmitting: false,
        error: authErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> submitVerification({
    required String email,
    required String code,
  }) async {
    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await ref.read(authRepositoryProvider).verifyEmailCode(
            email: email.trim(),
            code: code.trim(),
          );
      state = state.copyWith(isSubmitting: false, clearError: true);
      return true;
    } catch (error) {
      _syncCooldownFromError(error);
      state = state.copyWith(
        isSubmitting: false,
        error: authErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> resendVerificationCode({required String email}) async {
    if (!state.canResend) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final response =
          await ref.read(authRepositoryProvider).resendEmailVerificationCode(
                email: email.trim(),
              );
      final result = registerStartResultFromResponse(response);

      _startResendCountdown(result.canResendInSeconds);
      state = state.copyWith(isSubmitting: false, clearError: true);
      return true;
    } catch (error) {
      _syncCooldownFromError(error);
      state = state.copyWith(
        isSubmitting: false,
        error: authErrorMessage(error),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _syncCooldownFromError(Object error) {
    final seconds = authResendCooldownFromError(error);
    if (seconds != null && seconds > 0) {
      _startResendCountdown(seconds);
    }
  }

  void _startResendCountdown(int seconds) {
    _resendCountdown.start(
      seconds,
      onChanged: (seconds) {
        state = state.copyWith(canResendInSeconds: seconds);
      },
    );
  }

  String? _optionalName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
