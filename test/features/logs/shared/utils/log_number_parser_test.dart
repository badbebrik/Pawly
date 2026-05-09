import 'package:flutter_test/flutter_test.dart';
import 'package:pawly/features/logs/shared/utils/log_number_parser.dart';

void main() {
  group('parseLogNumber', () {
    test('parses dot and comma decimals', () {
      expect(parseLogNumber('1.5'), 1.5);
      expect(parseLogNumber('1,5'), 1.5);
    });

    test('trims whitespace', () {
      expect(parseLogNumber('  42  '), 42);
    });

    test('returns null for empty and invalid values', () {
      expect(parseLogNumber(''), isNull);
      expect(parseLogNumber('   '), isNull);
      expect(parseLogNumber('abc'), isNull);
    });
  });
}
