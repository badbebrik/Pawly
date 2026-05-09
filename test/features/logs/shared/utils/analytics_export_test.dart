import 'package:flutter_test/flutter_test.dart';
import 'package:pawly/features/logs/models/analytics_models.dart';
import 'package:pawly/features/logs/models/log_constants.dart';
import 'package:pawly/features/logs/shared/utils/analytics_export.dart';

void main() {
  group('buildAnalyticsMetricSeriesCsv', () {
    test('exports header and numeric rows with BOM', () {
      final csv = buildAnalyticsMetricSeriesCsv(
        metric: _metric(
          name: 'Вес',
          inputKind: LogMetricInputKind.numeric,
          unitCode: 'kg',
        ),
        series: _series(
          inputKind: LogMetricInputKind.numeric,
          unitCode: 'kg',
          points: <MetricSeriesPointItem>[
            MetricSeriesPointItem(
              occurredAt: DateTime(2026, 1, 2, 3, 4, 5),
              valueNum: 4.25,
              logId: 'log-1',
              logTypeName: 'Осмотр',
              source: LogSource.user,
            ),
          ],
        ),
      );

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(
        csv,
        contains(
          'Дата и время,Показатель,Тип показателя,Значение,Единица,'
          'Тип записи,Источник,ID записи',
        ),
      );
      expect(csv, contains('2026-01-02 03:04:05,Вес,Число,4.25,кг,Осмотр'));
    });

    test('exports scale values as numbers', () {
      final csv = buildAnalyticsMetricSeriesCsv(
        metric:
            _metric(name: 'Настроение', inputKind: LogMetricInputKind.scale),
        series: _series(
          inputKind: LogMetricInputKind.scale,
          points: const <MetricSeriesPointItem>[
            MetricSeriesPointItem(valueNum: 5, logId: 'log-1', source: 'USER'),
          ],
        ),
      );

      expect(csv, contains('Настроение,Шкала,5,,,USER,log-1'));
    });

    test('exports boolean values as Да and Нет', () {
      final csv = buildAnalyticsMetricSeriesCsv(
        metric: _metric(name: 'Ел', inputKind: LogMetricInputKind.boolean),
        series: _series(
          inputKind: LogMetricInputKind.boolean,
          points: const <MetricSeriesPointItem>[
            MetricSeriesPointItem(valueNum: 1, logId: 'yes', source: 'USER'),
            MetricSeriesPointItem(valueNum: 0, logId: 'no', source: 'USER'),
          ],
        ),
      );

      expect(csv, contains('Ел,Да / Нет,Да,,,USER,yes'));
      expect(csv, contains('Ел,Да / Нет,Нет,,,USER,no'));
    });

    test('escapes commas, quotes and line breaks', () {
      final csv = buildAnalyticsMetricSeriesCsv(
        metric: _metric(
          name: 'Вес, "утренний"',
          inputKind: LogMetricInputKind.numeric,
        ),
        series: _series(
          inputKind: LogMetricInputKind.numeric,
          points: const <MetricSeriesPointItem>[
            MetricSeriesPointItem(
              valueNum: 1,
              logId: 'log-1',
              logTypeName: 'До еды\nпосле воды',
              source: 'USER',
            ),
          ],
        ),
      );

      expect(csv, contains('"Вес, ""утренний"""'));
      expect(csv, contains('"До еды\nпосле воды"'));
    });
  });

  group('analyticsMetricSeriesExportFileName', () {
    test('uses a safe metric name and csv extension', () {
      final fileName = analyticsMetricSeriesExportFileName(
        _metric(name: 'Вес / Утро!?', inputKind: LogMetricInputKind.numeric),
      );

      expect(fileName, startsWith('pawly_вес_утро_'));
      expect(fileName, endsWith('.csv'));
      expect(fileName, isNot(contains('/')));
      expect(fileName, isNot(contains('!')));
      expect(fileName, isNot(contains('?')));
    });
  });
}

AnalyticsMetricItem _metric({
  required String name,
  required String inputKind,
  String? unitCode,
}) {
  return AnalyticsMetricItem(
    metricId: 'metric-1',
    metricName: name,
    metricScope: LogTypeScope.system,
    inputKind: inputKind,
    unitCode: unitCode,
    pointsCount: 1,
    usedInLogTypes: const <AnalyticsMetricLogTypeItem>[],
  );
}

MetricSeries _series({
  required String inputKind,
  String? unitCode,
  required List<MetricSeriesPointItem> points,
}) {
  return MetricSeries(
    metric: MetricSeriesMetric(
      id: 'metric-1',
      scope: LogTypeScope.system,
      name: 'Metric',
      inputKind: inputKind,
      unitCode: unitCode,
    ),
    points: points,
  );
}
