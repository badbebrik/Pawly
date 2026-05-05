class HealthDictionaryRefInput {
  const HealthDictionaryRefInput({
    this.id,
    this.name,
  });

  final String? id;
  final String? name;
}

class HealthEntityReminderInput {
  const HealthEntityReminderInput({
    required this.pushEnabled,
    this.remindOffsetMinutes,
  });

  final bool pushEnabled;
  final int? remindOffsetMinutes;
}
