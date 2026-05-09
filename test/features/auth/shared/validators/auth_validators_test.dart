import 'package:flutter_test/flutter_test.dart';
import 'package:pawly/features/auth/shared/validators/auth_validators.dart';

void main() {
  group('AuthValidators.email', () {
    test('accepts a valid email and trims spaces', () {
      expect(AuthValidators.email(' user@example.com '), isNull);
    });

    test('rejects empty and malformed emails', () {
      expect(AuthValidators.email(''), 'Введите email');
      expect(AuthValidators.email('user example.com'), 'Некорректный email');
      expect(AuthValidators.email('@example.com'), 'Некорректный email');
      expect(AuthValidators.email('user@example'), 'Некорректный email');
      expect(AuthValidators.email('user@example.c'), 'Некорректный email');
    });
  });

  group('AuthValidators.password', () {
    test('requires a non-empty password with at least 8 chars', () {
      expect(AuthValidators.password(''), 'Введите пароль');
      expect(AuthValidators.password('1234567'), 'Минимум 8 символов');
      expect(AuthValidators.password('12345678'), isNull);
    });
  });

  group('AuthValidators.requiredCode', () {
    test('requires exactly six digits', () {
      expect(AuthValidators.requiredCode(''), 'Введите код');
      expect(
          AuthValidators.requiredCode('12345'), 'Код должен содержать 6 цифр');
      expect(AuthValidators.requiredCode('12345a'), 'Только цифры');
      expect(AuthValidators.requiredCode('123456'), isNull);
    });
  });

  group('AuthValidators.confirmPassword', () {
    test('requires confirmation to match password', () {
      expect(
          AuthValidators.confirmPassword('', 'password'), 'Повторите пароль');
      expect(
        AuthValidators.confirmPassword('password1', 'password'),
        'Пароли не совпадают',
      );
      expect(AuthValidators.confirmPassword('password', 'password'), isNull);
    });
  });
}
