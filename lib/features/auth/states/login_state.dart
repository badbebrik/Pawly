class LoginState {
  const LoginState({
    required this.isSubmitting,
    this.error,
  });

  const LoginState.initial()
      : isSubmitting = false,
        error = null;

  final bool isSubmitting;
  final String? error;

  LoginState copyWith({
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return LoginState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
