import 'package:flutter_test/flutter_test.dart';
import 'package:pawly/features/logs/models/log_constants.dart';
import 'package:pawly/features/logs/shared/validators/log_catalog_validator.dart';

void main() {
  group('validateLogMetricForm', () {
    test('creates a numeric metric with unit and range', () {
      final result = validateLogMetricForm(
        name: ' Вес ',
        inputKind: LogMetricInputKind.numeric,
        unitCode: ' kg ',
        minValue: '1,5',
        maxValue: '10',
      );

      expect(result.isValid, isTrue);
      expect(result.form!.name, 'Вес');
      expect(result.form!.unitCode, 'kg');
      expect(result.form!.minValue, 1.5);
      expect(result.form!.maxValue, 10);
    });

    test('requires min and max for scale metrics', () {
      final result = validateLogMetricForm(
        name: 'Настроение',
        inputKind: LogMetricInputKind.scale,
        unitCode: '',
        minValue: '',
        maxValue: '5',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('минимум и максимум'));
    });

    test('rejects unit and range for boolean metrics', () {
      final result = validateLogMetricForm(
        name: 'Ел',
        inputKind: LogMetricInputKind.boolean,
        unitCode: 'раз',
        minValue: '',
        maxValue: '',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('должны быть пустыми'));
    });

    test('normalizes valid boolean metrics to empty unit and range', () {
      final result = validateLogMetricForm(
        name: 'Ел',
        inputKind: LogMetricInputKind.boolean,
        unitCode: '',
        minValue: '',
        maxValue: '',
      );

      expect(result.isValid, isTrue);
      expect(result.form!.unitCode, isNull);
      expect(result.form!.minValue, isNull);
      expect(result.form!.maxValue, isNull);
    });

    test('requires min to be less than max', () {
      final result = validateLogMetricForm(
        name: 'Вес',
        inputKind: LogMetricInputKind.numeric,
        unitCode: '',
        minValue: '5',
        maxValue: '5',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Минимум'));
    });
  });

  group('validateLogTypeForm', () {
    test('creates metric selections from selected metrics', () {
      final result = validateLogTypeForm(
        name: ' Осмотр ',
        selectedMetrics: const <String, bool>{
          'weight': true,
          'mood': false,
        },
      );

      expect(result.isValid, isTrue);
      expect(result.form!.name, 'Осмотр');
      expect(result.form!.metricSelections, hasLength(2));
      expect(result.form!.metricSelections.first.metricId, 'weight');
      expect(result.form!.metricSelections.first.isRequired, isTrue);
    });
  });
}
