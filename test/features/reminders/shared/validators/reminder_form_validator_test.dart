import 'package:flutter_test/flutter_test.dart';
import 'package:pawly/features/reminders/shared/validators/reminder_form_validator.dart';

void main() {
  group('validateReminderTitle', () {
    test('requires non-empty title', () {
      expect(validateReminderTitle(null), 'Укажите название');
      expect(validateReminderTitle('   '), 'Укажите название');
      expect(validateReminderTitle('Вакцинация'), isNull);
    });
  });

  group('validateReminderInterval', () {
    test('skips validation when recurrence is disabled', () {
      expect(validateReminderInterval('', isEnabled: false), isNull);
      expect(validateReminderInterval('abc', isEnabled: false), isNull);
    });

    test('requires a positive integer when enabled', () {
      expect(
        validateReminderInterval('', isEnabled: true),
        'Интервал должен быть больше 0',
      );
      expect(
        validateReminderInterval('0', isEnabled: true),
        'Интервал должен быть больше 0',
      );
      expect(
        validateReminderInterval('-1', isEnabled: true),
        'Интервал должен быть больше 0',
      );
      expect(
        validateReminderInterval('abc', isEnabled: true),
        'Интервал должен быть больше 0',
      );
      expect(validateReminderInterval('1', isEnabled: true), isNull);
    });
  });
}
