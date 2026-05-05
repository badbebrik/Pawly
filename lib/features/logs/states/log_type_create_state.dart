class LogTypeCreateState {
  const LogTypeCreateState({
    required this.isSubmitting,
  });

  factory LogTypeCreateState.initial() {
    return const LogTypeCreateState(isSubmitting: false);
  }

  final bool isSubmitting;

  LogTypeCreateState copyWith({
    bool? isSubmitting,
  }) {
    return LogTypeCreateState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
