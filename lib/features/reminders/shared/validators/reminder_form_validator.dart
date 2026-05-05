String? validateReminderTitle(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Укажите название';
  }
  return null;
}

String? validateReminderInterval(String? value, {required bool isEnabled}) {
  if (!isEnabled) {
    return null;
  }
  final parsed = int.tryParse((value ?? '').trim());
  if (parsed == null || parsed <= 0) {
    return 'Интервал должен быть больше 0';
  }
  return null;
}
