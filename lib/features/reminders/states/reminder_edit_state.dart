class ReminderEditState {
  const ReminderEditState({
    required this.isSubmitting,
  });

  factory ReminderEditState.initial() {
    return const ReminderEditState(isSubmitting: false);
  }

  final bool isSubmitting;

  ReminderEditState copyWith({
    bool? isSubmitting,
  }) {
    return ReminderEditState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
