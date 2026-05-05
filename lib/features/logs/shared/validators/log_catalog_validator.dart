import '../../models/log_metric_form.dart';
import '../../models/log_constants.dart';
import '../../models/log_type_form.dart';
import '../utils/log_number_parser.dart';

class LogMetricFormValidationResult {
  const LogMetricFormValidationResult._({
    this.form,
    this.errorMessage,
  });

  factory LogMetricFormValidationResult.success(LogMetricForm form) {
    return LogMetricFormValidationResult._(form: form);
  }

  factory LogMetricFormValidationResult.failure(String message) {
    return LogMetricFormValidationResult._(errorMessage: message);
  }

  final LogMetricForm? form;
  final String? errorMessage;

  bool get isValid => errorMessage == null;
}

class LogTypeFormValidationResult {
  const LogTypeFormValidationResult._({
    this.form,
    this.errorMessage,
  });

  factory LogTypeFormValidationResult.success(LogTypeForm form) {
    return LogTypeFormValidationResult._(form: form);
  }

  factory LogTypeFormValidationResult.failure(String message) {
    return LogTypeFormValidationResult._(errorMessage: message);
  }

  final LogTypeForm? form;
  final String? errorMessage;

  bool get isValid => errorMessage == null;
}

LogMetricFormValidationResult validateLogMetricForm({
  required String name,
  required String inputKind,
  required String unitCode,
  required String minValue,
  required String maxValue,
}) {
  final normalizedName = name.trim();
  if (normalizedName.isEmpty) {
    return LogMetricFormValidationResult.failure(
      'Укажите название показателя.',
    );
  }

  final parsedMin = parseLogNumber(minValue);
  final parsedMax = parseLogNumber(maxValue);
  final normalizedUnitCode = unitCode.trim().isEmpty ? null : unitCode.trim();

  if (inputKind == LogMetricInputKind.scale &&
      (parsedMin == null || parsedMax == null)) {
    return LogMetricFormValidationResult.failure(
      'Для шкалы нужно указать минимум и максимум.',
    );
  }
  if (inputKind == LogMetricInputKind.boolean &&
      (normalizedUnitCode != null || parsedMin != null || parsedMax != null)) {
    return LogMetricFormValidationResult.failure(
      'Для boolean единица измерения и диапазон должны быть пустыми.',
    );
  }
  if (parsedMin != null && parsedMax != null && parsedMin >= parsedMax) {
    return LogMetricFormValidationResult.failure(
      'Минимум должен быть меньше максимума.',
    );
  }

  return LogMetricFormValidationResult.success(
    LogMetricForm(
      name: normalizedName,
      inputKind: inputKind,
      unitCode:
          inputKind == LogMetricInputKind.boolean ? null : normalizedUnitCode,
      minValue: inputKind == LogMetricInputKind.boolean ? null : parsedMin,
      maxValue: inputKind == LogMetricInputKind.boolean ? null : parsedMax,
    ),
  );
}

LogTypeFormValidationResult validateLogTypeForm({
  required String name,
  required Map<String, bool> selectedMetrics,
}) {
  final normalizedName = name.trim();
  if (normalizedName.isEmpty) {
    return LogTypeFormValidationResult.failure('Укажите название типа.');
  }

  return LogTypeFormValidationResult.success(
    LogTypeForm(
      name: normalizedName,
      metricSelections: selectedMetrics.entries
          .map(
            (entry) => LogTypeMetricSelection(
              metricId: entry.key,
              isRequired: entry.value,
            ),
          )
          .toList(growable: false),
    ),
  );
}
