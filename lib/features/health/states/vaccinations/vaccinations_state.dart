import '../../models/health_models.dart';

enum VaccinationBucket { planned, history }

class PetVaccinationRef {
  const PetVaccinationRef({
    required this.petId,
    required this.vaccinationId,
  });

  final String petId;
  final String vaccinationId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PetVaccinationRef &&
            other.petId == petId &&
            other.vaccinationId == vaccinationId;
  }

  @override
  int get hashCode => Object.hash(petId, vaccinationId);
}

class PetVaccinationsState {
  const PetVaccinationsState({
    required this.petName,
    required this.bootstrap,
    required this.plannedItems,
    required this.historyItems,
    required this.plannedNextCursor,
    required this.historyNextCursor,
    required this.loadingMoreBucket,
    required this.searchQuery,
    required this.isCreating,
    required this.busyVaccinationIds,
  });

  final String petName;
  final HealthBootstrapResponse bootstrap;
  final List<VaccinationCard> plannedItems;
  final List<VaccinationCard> historyItems;
  final String? plannedNextCursor;
  final String? historyNextCursor;
  final VaccinationBucket? loadingMoreBucket;
  final String searchQuery;
  final bool isCreating;
  final Set<String> busyVaccinationIds;

  bool get canRead => bootstrap.permissions.healthRead;
  bool get canWrite => bootstrap.permissions.healthWrite;

  List<VaccinationCard> itemsFor(VaccinationBucket bucket) {
    return switch (bucket) {
      VaccinationBucket.planned => plannedItems,
      VaccinationBucket.history => historyItems,
    };
  }

  String? nextCursorFor(VaccinationBucket bucket) {
    return switch (bucket) {
      VaccinationBucket.planned => plannedNextCursor,
      VaccinationBucket.history => historyNextCursor,
    };
  }

  bool isLoadingMore(VaccinationBucket bucket) => loadingMoreBucket == bucket;

  PetVaccinationsState copyWith({
    String? petName,
    HealthBootstrapResponse? bootstrap,
    List<VaccinationCard>? plannedItems,
    List<VaccinationCard>? historyItems,
    String? plannedNextCursor,
    bool clearPlannedNextCursor = false,
    String? historyNextCursor,
    bool clearHistoryNextCursor = false,
    VaccinationBucket? loadingMoreBucket,
    bool clearLoadingMoreBucket = false,
    String? searchQuery,
    bool? isCreating,
    Set<String>? busyVaccinationIds,
  }) {
    return PetVaccinationsState(
      petName: petName ?? this.petName,
      bootstrap: bootstrap ?? this.bootstrap,
      plannedItems: plannedItems ?? this.plannedItems,
      historyItems: historyItems ?? this.historyItems,
      plannedNextCursor: clearPlannedNextCursor
          ? null
          : plannedNextCursor ?? this.plannedNextCursor,
      historyNextCursor: clearHistoryNextCursor
          ? null
          : historyNextCursor ?? this.historyNextCursor,
      loadingMoreBucket: clearLoadingMoreBucket
          ? null
          : loadingMoreBucket ?? this.loadingMoreBucket,
      searchQuery: searchQuery ?? this.searchQuery,
      isCreating: isCreating ?? this.isCreating,
      busyVaccinationIds: busyVaccinationIds ?? this.busyVaccinationIds,
    );
  }
}
