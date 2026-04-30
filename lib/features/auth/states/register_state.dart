import '../models/register_step.dart';

class RegisterState {
  const RegisterState({
    required this.step,
    required this.isSubmitting,
    required this.canResendInSeconds,
    this.error,
  });

  const RegisterState.initial()
      : step = RegisterStep.name,
        isSubmitting = false,
        canResendInSeconds = 0,
        error = null;

  final RegisterStep step;
  final bool isSubmitting;
  final int canResendInSeconds;
  final String? error;

  bool get canResend => !isSubmitting && canResendInSeconds == 0;

  RegisterState copyWith({
    RegisterStep? step,
    bool? isSubmitting,
    int? canResendInSeconds,
    String? error,
    bool clearError = false,
  }) {
    return RegisterState(
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      canResendInSeconds: canResendInSeconds ?? this.canResendInSeconds,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
