class AuthValidators {
  const AuthValidators._();

  static String? email(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Введите email';
    }

    if (!_isValidEmail(text)) {
      return 'Некорректный email';
    }

    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Введите пароль';
    }

    if (text.length < 8) {
      return 'Минимум 8 символов';
    }

    return null;
  }

  static String? requiredCode(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Введите код';
    }

    if (text.length != 6) {
      return 'Код должен содержать 6 цифр';
    }

    if (int.tryParse(text) == null) {
      return 'Только цифры';
    }

    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Повторите пароль';
    }

    if (text != password) {
      return 'Пароли не совпадают';
    }

    return null;
  }
}

bool _isValidEmail(String value) {
  if (value.contains(' ') || value.startsWith('@') || value.endsWith('@')) {
    return false;
  }

  final parts = value.split('@');
  if (parts.length != 2) {
    return false;
  }

  final local = parts[0];
  final domain = parts[1];
  if (local.isEmpty || domain.isEmpty || !domain.contains('.')) {
    return false;
  }

  final domainParts = domain.split('.');
  return domainParts.every((part) => part.isNotEmpty) &&
      domainParts.last.length >= 2;
}
