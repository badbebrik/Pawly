import 'package:flutter_test/flutter_test.dart';
import 'package:pawly/features/logs/models/log_constants.dart';
import 'package:pawly/features/logs/shared/formatters/analytics_formatters.dart';

void main() {
  group('formatAnalyticsMetricValue', () {
    test('formats boolean values as Да and Нет', () {
      expect(formatAnalyticsMetricValue(1, LogMetricInputKind.boolean, null),
          'Да');
      expect(formatAnalyticsMetricValue(0, LogMetricInputKind.boolean, null),
          'Нет');
    });

    test('formats numeric values with display units', () {
      expect(formatAnalyticsMetricValue(4, LogMetricInputKind.numeric, 'kg'),
          '4 кг');
      expect(
        formatAnalyticsMetricValue(4.25, LogMetricInputKind.numeric, 'kg'),
        '4.3 кг',
      );
    });
  });

  group('formatAnalyticsMetricSum', () {
    test('hides irrelevant boolean and scale sums', () {
      expect(
          formatAnalyticsMetricSum(2, LogMetricInputKind.boolean, null), '—');
      expect(formatAnalyticsMetricSum(12, LogMetricInputKind.scale, null), '—');
    });

    test('formats numeric sum', () {
      expect(formatAnalyticsMetricSum(12, LogMetricInputKind.numeric, 'g'),
          '12 г');
    });
  });

  group('formatAnalyticsMetricSummaryValue', () {
    test('hides irrelevant boolean aggregate values', () {
      expect(
        formatAnalyticsMetricSummaryValue(1, LogMetricInputKind.boolean, null),
        '—',
      );
    });

    test('keeps scale aggregate values', () {
      expect(
        formatAnalyticsMetricSummaryValue(4.5, LogMetricInputKind.scale, null),
        '4.5',
      );
    });
  });
}
