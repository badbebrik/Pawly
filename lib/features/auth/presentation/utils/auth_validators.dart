class AuthValidators {
  const AuthValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  static String? email(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Введите email';
    }

    if (!_emailRegex.hasMatch(text)) {
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
