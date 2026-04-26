String activePetAgeLabel(DateTime? birthDate) {
  if (birthDate == null) {
    return 'возраст неизвестен';
  }

  final now = DateTime.now();
  var years = now.year - birthDate.year;
  var months = now.month - birthDate.month;

  if (now.day < birthDate.day) {
    months -= 1;
  }

  if (months < 0) {
    years -= 1;
    months += 12;
  }

  if (years > 0) {
    return '$years ${_yearsWord(years)}';
  }
  if (months > 0) {
    return '$months ${_monthsWord(months)}';
  }
  return 'меньше месяца';
}

String _yearsWord(int value) {
  final mod10 = value % 10;
  final mod100 = value % 100;
  if (mod10 == 1 && mod100 != 11) {
    return 'год';
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'года';
  }
  return 'лет';
}

String _monthsWord(int value) {
  final mod10 = value % 10;
  final mod100 = value % 100;
  if (mod10 == 1 && mod100 != 11) {
    return 'месяц';
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'месяца';
  }
  return 'месяцев';
}
