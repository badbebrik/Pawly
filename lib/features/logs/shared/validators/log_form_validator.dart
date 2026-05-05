import '../../models/log_form.dart';
import '../../models/log_constants.dart';
import '../../models/log_models.dart';
import '../formatters/log_form_formatters.dart';
import '../utils/log_number_parser.dart';

class LogMetricValidationResult {
  const LogMetricValidationResult._({
    required this.values,
    this.errorMessage,
  });

  factory LogMetricValidationResult.success(
    List<LogFormMetricValue> values,
  ) {
    return LogMetricValidationResult._(values: values);
  }

  factory LogMetricValidationResult.failure(String message) {
    return LogMetricValidationResult._(
      values: const <LogFormMetricValue>[],
      errorMessage: message,
    );
  }

  final List<LogFormMetricValue> values;
  final String? errorMessage;

  bool get isValid => errorMessage == null;
}

LogMetricValidationResult validateLogMetricValues({
  required Iterable<LogTypeMetricRequirementItem> requirements,
  required String Function(String metricId) textValueForMetric,
  required bool? Function(String metricId) booleanValueForMetric,
}) {
  final values = <LogFormMetricValue>[];

  for (final requirement in requirements) {
    if (requirement.inputKind == LogMetricInputKind.boolean) {
      final selectedValue = booleanValueForMetric(requirement.metricId);
      if (selectedValue == null) {
        if (requirement.isRequired) {
          return LogMetricValidationResult.failure(
            'Заполните показатель "${logMetricRequirementName(requirement)}".',
          );
        }
        continue;
      }

      values.add(
        LogFormMetricValue(
          metricId: requirement.metricId,
          valueNum: selectedValue ? 1 : 0,
        ),
      );
      continue;
    }

    final rawValue = textValueForMetric(requirement.metricId).trim();
    if (rawValue.isEmpty) {
      if (requirement.isRequired) {
        return LogMetricValidationResult.failure(
          'Заполните показатель "${logMetricRequirementName(requirement)}".',
        );
      }
      continue;
    }

    final value = parseLogNumber(rawValue);
    if (value == null) {
      return LogMetricValidationResult.failure(
        'Показатель "${logMetricRequirementName(requirement)}" должен быть числом.',
      );
    }

    values.add(
      LogFormMetricValue(metricId: requirement.metricId, valueNum: value),
    );
  }

  return LogMetricValidationResult.success(values);
}
