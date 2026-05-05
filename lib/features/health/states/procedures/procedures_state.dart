import '../../models/health_models.dart';

enum ProcedureBucket { planned, history }

class PetProcedureRef {
  const PetProcedureRef({
    required this.petId,
    required this.procedureId,
  });

  final String petId;
  final String procedureId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PetProcedureRef &&
            other.petId == petId &&
            other.procedureId == procedureId;
  }

  @override
  int get hashCode => Object.hash(petId, procedureId);
}

class PetProceduresState {
  const PetProceduresState({
    required this.petName,
    required this.bootstrap,
    required this.plannedItems,
    required this.historyItems,
    required this.plannedNextCursor,
    required this.historyNextCursor,
    required this.loadingMoreBucket,
    required this.searchQuery,
    required this.isCreating,
    required this.busyProcedureIds,
  });

  final String petName;
  final HealthBootstrapResponse bootstrap;
  final List<ProcedureCard> plannedItems;
  final List<ProcedureCard> historyItems;
  final String? plannedNextCursor;
  final String? historyNextCursor;
  final ProcedureBucket? loadingMoreBucket;
  final String searchQuery;
  final bool isCreating;
  final Set<String> busyProcedureIds;

  bool get canRead => bootstrap.permissions.healthRead;
  bool get canWrite => bootstrap.permissions.healthWrite;

  List<ProcedureCard> itemsFor(ProcedureBucket bucket) {
    return switch (bucket) {
      ProcedureBucket.planned => plannedItems,
      ProcedureBucket.history => historyItems,
    };
  }

  String? nextCursorFor(ProcedureBucket bucket) {
    return switch (bucket) {
      ProcedureBucket.planned => plannedNextCursor,
      ProcedureBucket.history => historyNextCursor,
    };
  }

  bool isLoadingMore(ProcedureBucket bucket) => loadingMoreBucket == bucket;

  PetProceduresState copyWith({
    String? petName,
    HealthBootstrapResponse? bootstrap,
    List<ProcedureCard>? plannedItems,
    List<ProcedureCard>? historyItems,
    String? plannedNextCursor,
    bool clearPlannedNextCursor = false,
    String? historyNextCursor,
    bool clearHistoryNextCursor = false,
    ProcedureBucket? loadingMoreBucket,
    bool clearLoadingMoreBucket = false,
    String? searchQuery,
    bool? isCreating,
    Set<String>? busyProcedureIds,
  }) {
    return PetProceduresState(
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
      busyProcedureIds: busyProcedureIds ?? this.busyProcedureIds,
    );
  }
}
