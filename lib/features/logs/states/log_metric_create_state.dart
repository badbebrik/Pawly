class LogMetricCreateState {
  const LogMetricCreateState({
    required this.isSubmitting,
  });

  factory LogMetricCreateState.initial() {
    return const LogMetricCreateState(isSubmitting: false);
  }

  final bool isSubmitting;

  LogMetricCreateState copyWith({
    bool? isSubmitting,
  }) {
    return LogMetricCreateState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
