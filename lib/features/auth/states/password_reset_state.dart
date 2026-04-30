class PasswordResetState {
  const PasswordResetState({
    required this.isRequestingCode,
    required this.isVerifyingCode,
    required this.isResendingCode,
    required this.isConfirmingPassword,
    required this.canResendInSeconds,
    this.error,
  });

  const PasswordResetState.initial()
      : isRequestingCode = false,
        isVerifyingCode = false,
        isResendingCode = false,
        isConfirmingPassword = false,
        canResendInSeconds = 0,
        error = null;

  final bool isRequestingCode;
  final bool isVerifyingCode;
  final bool isResendingCode;
  final bool isConfirmingPassword;
  final int canResendInSeconds;
  final String? error;

  bool get isVerifyingBusy => isVerifyingCode || isResendingCode;
  bool get canResendCode => !isVerifyingBusy && canResendInSeconds == 0;

  PasswordResetState copyWith({
    bool? isRequestingCode,
    bool? isVerifyingCode,
    bool? isResendingCode,
    bool? isConfirmingPassword,
    int? canResendInSeconds,
    String? error,
    bool clearError = false,
  }) {
    return PasswordResetState(
      isRequestingCode: isRequestingCode ?? this.isRequestingCode,
      isVerifyingCode: isVerifyingCode ?? this.isVerifyingCode,
      isResendingCode: isResendingCode ?? this.isResendingCode,
      isConfirmingPassword: isConfirmingPassword ?? this.isConfirmingPassword,
      canResendInSeconds: canResendInSeconds ?? this.canResendInSeconds,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
