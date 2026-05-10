import '../../models/analytics_models.dart';
import '../../models/log_constants.dart';
import '../formatters/analytics_formatters.dart';
import '../formatters/log_metric_formatters.dart';

const analyticsCsvMimeType = 'text/csv';

String buildAnalyticsMetricSeriesCsv({
  required AnalyticsMetricItem metric,
  required MetricSeries series,
}) {
  final buffer = StringBuffer();
  writeAnalyticsMetricSeriesCsv(
    sink: buffer,
    metric: metric,
    series: series,
  );
  return buffer.toString();
}

void writeAnalyticsMetricSeriesCsv({
  required StringSink sink,
  required AnalyticsMetricItem metric,
  required MetricSeries series,
}) {
  sink.write('\uFEFF');
  _writeCsvRow(sink, const <String>[
    'Дата и время',
    'Показатель',
    'Тип показателя',
    'Значение',
    'Единица',
    'Тип записи',
    'Источник',
    'ID записи',
  ]);

  for (final point in series.points) {
    _writeCsvRow(sink, <String>[
      formatAnalyticsExportDateTime(point.occurredAt),
      metric.metricName,
      analyticsMetricKindLabel(metric.inputKind),
      formatAnalyticsExportValue(point.valueNum, metric.inputKind),
      formatDisplayUnitCode(metric.unitCode),
      point.logTypeName ?? '',
      point.source,
      point.logId,
    ]);
  }
}

String analyticsMetricSeriesExportFileName(AnalyticsMetricItem metric) {
  final metricName =
      metric.metricName.trim().isEmpty ? 'metric' : metric.metricName.trim();
  final safeMetricName = _safeFileNamePart(metricName);
  final timestamp = _compactTimestamp(DateTime.now());
  return 'pawly_${safeMetricName.isEmpty ? 'metric' : safeMetricName}_$timestamp.csv';
}

String formatAnalyticsExportDateTime(DateTime? value) {
  if (value == null) {
    return '';
  }
  final local = value.toLocal();
  final date = [
    local.year.toString().padLeft(4, '0'),
    local.month.toString().padLeft(2, '0'),
    local.day.toString().padLeft(2, '0'),
  ].join('-');
  final time = [
    local.hour.toString().padLeft(2, '0'),
    local.minute.toString().padLeft(2, '0'),
    local.second.toString().padLeft(2, '0'),
  ].join(':');
  return '$date $time';
}

String formatAnalyticsExportValue(double value, String inputKind) {
  if (inputKind == LogMetricInputKind.boolean) {
    return value == 0 ? 'Нет' : 'Да';
  }
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
}

void _writeCsvRow(StringSink sink, Iterable<String> row) {
  var isFirst = true;
  for (final cell in row) {
    if (isFirst) {
      isFirst = false;
    } else {
      sink.write(',');
    }
    sink.write(_escapeCsvCell(cell));
  }
  sink.writeln();
}

String _escapeCsvCell(String value) {
  if (!value.contains('"') &&
      !value.contains(',') &&
      !value.contains('\r') &&
      !value.contains('\n')) {
    return value;
  }
  return '"${value.replaceAll('"', '""')}"';
}

String _safeFileNamePart(String value) {
  final buffer = StringBuffer();
  var previousWasSeparator = false;

  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    if (_isSafeFileNameRune(rune)) {
      buffer.write(char);
      previousWasSeparator = false;
      continue;
    }

    if (!previousWasSeparator && buffer.isNotEmpty) {
      buffer.write('_');
      previousWasSeparator = true;
    }
  }

  final result = buffer.toString();
  if (result.endsWith('_')) {
    return result.substring(0, result.length - 1);
  }
  return result;
}

bool _isSafeFileNameRune(int rune) {
  return (rune >= 0x30 && rune <= 0x39) ||
      (rune >= 0x61 && rune <= 0x7A) ||
      (rune >= 0x430 && rune <= 0x44F) ||
      rune == 0x451;
}

String _compactTimestamp(DateTime value) {
  final local = value.toLocal();
  return [
    local.year.toString().padLeft(4, '0'),
    local.month.toString().padLeft(2, '0'),
    local.day.toString().padLeft(2, '0'),
    local.hour.toString().padLeft(2, '0'),
    local.minute.toString().padLeft(2, '0'),
  ].join();
}
