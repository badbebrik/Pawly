import 'package:flutter_test/flutter_test.dart';
import 'package:pawly/features/logs/models/log_constants.dart';
import 'package:pawly/features/logs/models/log_models.dart';
import 'package:pawly/features/logs/shared/validators/log_form_validator.dart';

void main() {
  group('validateLogMetricValues', () {
    test('maps required boolean true and false to numeric values', () {
      final trueResult = validateLogMetricValues(
        requirements: <LogTypeMetricRequirementItem>[
          _requirement(
            metricId: 'bool',
            inputKind: LogMetricInputKind.boolean,
            isRequired: true,
          ),
        ],
        textValueForMetric: (_) => '',
        booleanValueForMetric: (_) => true,
      );
      final falseResult = validateLogMetricValues(
        requirements: <LogTypeMetricRequirementItem>[
          _requirement(
            metricId: 'bool',
            inputKind: LogMetricInputKind.boolean,
            isRequired: true,
          ),
        ],
        textValueForMetric: (_) => '',
        booleanValueForMetric: (_) => false,
      );

      expect(trueResult.isValid, isTrue);
      expect(trueResult.values.single.valueNum, 1);
      expect(falseResult.isValid, isTrue);
      expect(falseResult.values.single.valueNum, 0);
    });

    test('skips empty optional metrics', () {
      final result = validateLogMetricValues(
        requirements: <LogTypeMetricRequirementItem>[
          _requirement(
            metricId: 'optional-text',
            inputKind: LogMetricInputKind.numeric,
          ),
          _requirement(
            metricId: 'optional-bool',
            inputKind: LogMetricInputKind.boolean,
          ),
        ],
        textValueForMetric: (_) => ' ',
        booleanValueForMetric: (_) => null,
      );

      expect(result.isValid, isTrue);
      expect(result.values, isEmpty);
    });

    test('fails when a required metric is empty', () {
      final result = validateLogMetricValues(
        requirements: <LogTypeMetricRequirementItem>[
          _requirement(
            metricId: 'weight',
            metricName: 'Вес',
            inputKind: LogMetricInputKind.numeric,
            isRequired: true,
          ),
        ],
        textValueForMetric: (_) => '',
        booleanValueForMetric: (_) => null,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Вес'));
    });

    test('fails when numeric metric is not a number', () {
      final result = validateLogMetricValues(
        requirements: <LogTypeMetricRequirementItem>[
          _requirement(
            metricId: 'weight',
            metricName: 'Вес',
            inputKind: LogMetricInputKind.numeric,
          ),
        ],
        textValueForMetric: (_) => 'abc',
        booleanValueForMetric: (_) => null,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('должен быть числом'));
    });

    test('parses comma decimal numbers', () {
      final result = validateLogMetricValues(
        requirements: <LogTypeMetricRequirementItem>[
          _requirement(
            metricId: 'weight',
            inputKind: LogMetricInputKind.numeric,
          ),
        ],
        textValueForMetric: (_) => ' 4,5 ',
        booleanValueForMetric: (_) => null,
      );

      expect(result.isValid, isTrue);
      expect(result.values.single.valueNum, 4.5);
    });
  });
}

LogTypeMetricRequirementItem _requirement({
  required String metricId,
  String metricName = 'Показатель',
  required String inputKind,
  bool isRequired = false,
}) {
  return LogTypeMetricRequirementItem(
    metricId: metricId,
    metricName: metricName,
    metricScope: LogTypeScope.system,
    inputKind: inputKind,
    isRequired: isRequired,
  );
}
