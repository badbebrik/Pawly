class LogCreateState {
  const LogCreateState({
    required this.isSubmitting,
  });

  factory LogCreateState.initial() {
    return const LogCreateState(isSubmitting: false);
  }

  final bool isSubmitting;

  LogCreateState copyWith({
    bool? isSubmitting,
  }) {
    return LogCreateState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
