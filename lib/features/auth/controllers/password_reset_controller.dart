import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/password_reset_verification.dart';
import '../shared/mappers/auth_mappers.dart';
import '../shared/utils/auth_error_message.dart';
import '../shared/utils/auth_resend_countdown.dart';
import '../shared/utils/auth_resend_cooldown.dart';
import '../states/password_reset_state.dart';
import 'auth_dependencies.dart';

const _passwordResetResendCooldown = 60;

final passwordResetControllerProvider =
    NotifierProvider.autoDispose<PasswordResetController, PasswordResetState>(
  PasswordResetController.new,
);

class PasswordResetController extends Notifier<PasswordResetState> {
  final _resendCountdown = AuthResendCountdown();

  @override
  PasswordResetState build() {
    ref.onDispose(() {
      _resendCountdown.dispose();
    });
    return const PasswordResetState.initial();
  }

  Future<bool> requestCode({required String email}) async {
    if (state.isRequestingCode) {
      return false;
    }

    state = state.copyWith(isRequestingCode: true, clearError: true);

    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(
            email: email.trim(),
          );
      _startResendCountdown(_passwordResetResendCooldown);
      state = state.copyWith(isRequestingCode: false, clearError: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isRequestingCode: false,
        error: authErrorMessage(error),
      );
      return false;
    }
  }

  Future<PasswordResetVerification?> verifyCode({
    required String email,
    required String code,
  }) async {
    if (state.isVerifyingBusy) {
      return null;
    }

    state = state.copyWith(isVerifyingCode: true, clearError: true);

    try {
      final response =
          await ref.read(authRepositoryProvider).verifyPasswordResetCode(
                email: email.trim(),
                code: code.trim(),
              );
      state = state.copyWith(isVerifyingCode: false, clearError: true);
      return passwordResetVerificationFromResponse(response);
    } catch (error) {
      _syncCooldownFromError(error);
      state = state.copyWith(
        isVerifyingCode: false,
        error: authErrorMessage(error),
      );
      return null;
    }
  }

  Future<bool> resendCode({required String email}) async {
    if (!state.canResendCode) {
      return false;
    }

    state = state.copyWith(isResendingCode: true, clearError: true);

    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(
            email: email.trim(),
          );
      _startResendCountdown(_passwordResetResendCooldown);
      state = state.copyWith(isResendingCode: false, clearError: true);
      return true;
    } catch (error) {
      _syncCooldownFromError(error);
      state = state.copyWith(
        isResendingCode: false,
        error: authErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> confirmPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    if (state.isConfirmingPassword) {
      return false;
    }

    state = state.copyWith(isConfirmingPassword: true, clearError: true);

    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            resetToken: resetToken,
            newPassword: newPassword,
          );
      state = state.copyWith(isConfirmingPassword: false, clearError: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isConfirmingPassword: false,
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
}
