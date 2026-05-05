class ReminderCreateState {
  const ReminderCreateState({
    required this.isSubmitting,
  });

  factory ReminderCreateState.initial() {
    return const ReminderCreateState(isSubmitting: false);
  }

  final bool isSubmitting;

  ReminderCreateState copyWith({
    bool? isSubmitting,
  }) {
    return ReminderCreateState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
