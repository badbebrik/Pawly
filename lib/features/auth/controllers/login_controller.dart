import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/utils/auth_error_message.dart';
import '../states/login_state.dart';
import 'auth_dependencies.dart';

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
  LoginController.new,
);

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState.initial();

  Future<bool> submitEmail({
    required String email,
    required String password,
  }) async {
    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await ref.read(authRepositoryProvider).loginWithEmail(
            email: email.trim(),
            password: password,
          );
      state = state.copyWith(isSubmitting: false, clearError: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        error: authErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> submitGoogle() async {
    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await ref.read(authRepositoryProvider).loginWithGoogle();
      state = state.copyWith(isSubmitting: false, clearError: true);
      return true;
    } catch (error) {
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
}
