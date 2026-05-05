class LogEditState {
  const LogEditState({
    required this.isSubmitting,
  });

  factory LogEditState.initial() {
    return const LogEditState(isSubmitting: false);
  }

  final bool isSubmitting;

  LogEditState copyWith({
    bool? isSubmitting,
  }) {
    return LogEditState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
