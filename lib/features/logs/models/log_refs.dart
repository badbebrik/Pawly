import 'package:flutter/foundation.dart';

class PetLogRef {
  const PetLogRef({
    required this.petId,
    required this.logId,
  });

  final String petId;
  final String logId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PetLogRef && other.petId == petId && other.logId == logId;
  }

  @override
  int get hashCode => Object.hash(petId, logId);
}

class PetMetricSeriesRef {
  const PetMetricSeriesRef({
    required this.petId,
    required this.metricId,
    this.dateFrom,
    this.dateTo,
    this.typeIds = const <String>[],
  });

  final String petId;
  final String metricId;
  final String? dateFrom;
  final String? dateTo;
  final List<String> typeIds;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PetMetricSeriesRef &&
            other.petId == petId &&
            other.metricId == metricId &&
            other.dateFrom == dateFrom &&
            other.dateTo == dateTo &&
            listEquals(other.typeIds, typeIds);
  }

  @override
  int get hashCode => Object.hash(
        petId,
        metricId,
        dateFrom,
        dateTo,
        Object.hashAll(typeIds),
      );
}

class PetAnalyticsMetricsRef {
  const PetAnalyticsMetricsRef({
    required this.petId,
    this.dateFrom,
    this.dateTo,
    this.typeIds = const <String>[],
  });

  final String petId;
  final String? dateFrom;
  final String? dateTo;
  final List<String> typeIds;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PetAnalyticsMetricsRef &&
            other.petId == petId &&
            other.dateFrom == dateFrom &&
            other.dateTo == dateTo &&
            listEquals(other.typeIds, typeIds);
  }

  @override
  int get hashCode => Object.hash(
        petId,
        dateFrom,
        dateTo,
        Object.hashAll(typeIds),
      );
}
