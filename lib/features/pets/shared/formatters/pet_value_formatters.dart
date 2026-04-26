String petMissingValueLabel(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Не заполнено' : trimmed;
}

String petSexLabel(String value) {
  switch (value) {
    case 'MALE':
      return 'Самец';
    case 'FEMALE':
      return 'Самка';
    default:
      return 'Не указан';
  }
}

String petYesNoUnknownLabel(String value) {
  switch (value) {
    case 'YES':
      return 'Да';
    case 'NO':
      return 'Нет';
    default:
      return 'Не указано';
  }
}

String petBooleanLabel(bool value) {
  return value ? 'Да' : 'Нет';
}

String petCardCountLabel(int value) {
  final mod10 = value % 10;
  final mod100 = value % 100;
  final word = mod10 == 1 && mod100 != 11
      ? 'карточка'
      : mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)
          ? 'карточки'
          : 'карточек';
  return '$value $word';
}
