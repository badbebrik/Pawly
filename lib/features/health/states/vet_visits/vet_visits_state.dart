import '../../models/health_models.dart';

enum VetVisitBucket { upcoming, history }

class VetVisitCreateResult {
  const VetVisitCreateResult({
    required this.visit,
    required this.relatedLogsLinked,
    required this.listReloaded,
  });

  final VetVisit visit;
  final bool relatedLogsLinked;
  final bool listReloaded;

  bool get hasPostCreateIssue => !relatedLogsLinked || !listReloaded;
}

class PetVetVisitRef {
  const PetVetVisitRef({
    required this.petId,
    required this.visitId,
  });

  final String petId;
  final String visitId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PetVetVisitRef &&
            other.petId == petId &&
            other.visitId == visitId;
  }

  @override
  int get hashCode => Object.hash(petId, visitId);
}

class PetVetVisitsState {
  const PetVetVisitsState({
    required this.petName,
    required this.bootstrap,
    required this.upcomingItems,
    required this.historyItems,
    required this.upcomingNextCursor,
    required this.historyNextCursor,
    required this.loadingMoreBucket,
    required this.searchQuery,
    required this.isCreating,
    required this.busyVisitIds,
  });

  final String petName;
  final HealthBootstrapResponse bootstrap;
  final List<VetVisitCard> upcomingItems;
  final List<VetVisitCard> historyItems;
  final String? upcomingNextCursor;
  final String? historyNextCursor;
  final VetVisitBucket? loadingMoreBucket;
  final String searchQuery;
  final bool isCreating;
  final Set<String> busyVisitIds;

  bool get canRead => bootstrap.permissions.healthRead;
  bool get canWrite => bootstrap.permissions.healthWrite;

  List<VetVisitCard> itemsFor(VetVisitBucket bucket) {
    return switch (bucket) {
      VetVisitBucket.upcoming => upcomingItems,
      VetVisitBucket.history => historyItems,
    };
  }

  String? nextCursorFor(VetVisitBucket bucket) {
    return switch (bucket) {
      VetVisitBucket.upcoming => upcomingNextCursor,
      VetVisitBucket.history => historyNextCursor,
    };
  }

  bool isLoadingMore(VetVisitBucket bucket) => loadingMoreBucket == bucket;

  PetVetVisitsState copyWith({
    String? petName,
    HealthBootstrapResponse? bootstrap,
    List<VetVisitCard>? upcomingItems,
    List<VetVisitCard>? historyItems,
    String? upcomingNextCursor,
    bool clearUpcomingNextCursor = false,
    String? historyNextCursor,
    bool clearHistoryNextCursor = false,
    VetVisitBucket? loadingMoreBucket,
    bool clearLoadingMoreBucket = false,
    String? searchQuery,
    bool? isCreating,
    Set<String>? busyVisitIds,
  }) {
    return PetVetVisitsState(
      petName: petName ?? this.petName,
      bootstrap: bootstrap ?? this.bootstrap,
      upcomingItems: upcomingItems ?? this.upcomingItems,
      historyItems: historyItems ?? this.historyItems,
      upcomingNextCursor: clearUpcomingNextCursor
          ? null
          : upcomingNextCursor ?? this.upcomingNextCursor,
      historyNextCursor: clearHistoryNextCursor
          ? null
          : historyNextCursor ?? this.historyNextCursor,
      loadingMoreBucket: clearLoadingMoreBucket
          ? null
          : loadingMoreBucket ?? this.loadingMoreBucket,
      searchQuery: searchQuery ?? this.searchQuery,
      isCreating: isCreating ?? this.isCreating,
      busyVisitIds: busyVisitIds ?? this.busyVisitIds,
    );
  }
}
