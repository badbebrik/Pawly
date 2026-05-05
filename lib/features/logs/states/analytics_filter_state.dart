import 'package:flutter/material.dart';

class AnalyticsFilterState {
  const AnalyticsFilterState({
    required this.range,
    required this.customDateRange,
    required this.dateFrom,
    required this.dateTo,
    required this.selectedTypeIds,
  });

  final String range;
  final DateTimeRange? customDateRange;
  final String? dateFrom;
  final String? dateTo;
  final Set<String> selectedTypeIds;
}
