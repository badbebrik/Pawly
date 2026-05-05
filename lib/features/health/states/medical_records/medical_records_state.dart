import '../../models/health_models.dart';

enum MedicalRecordBucket { active, archive }

class PetMedicalRecordRef {
  const PetMedicalRecordRef({
    required this.petId,
    required this.recordId,
  });

  final String petId;
  final String recordId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PetMedicalRecordRef &&
            other.petId == petId &&
            other.recordId == recordId;
  }

  @override
  int get hashCode => Object.hash(petId, recordId);
}

class PetMedicalRecordsState {
  const PetMedicalRecordsState({
    required this.petName,
    required this.bootstrap,
    required this.activeItems,
    required this.archiveItems,
    required this.activeNextCursor,
    required this.archiveNextCursor,
    required this.loadingMoreBucket,
    required this.searchQuery,
    required this.isCreating,
    required this.busyRecordIds,
  });

  final String petName;
  final HealthBootstrapResponse bootstrap;
  final List<MedicalRecordCard> activeItems;
  final List<MedicalRecordCard> archiveItems;
  final String? activeNextCursor;
  final String? archiveNextCursor;
  final MedicalRecordBucket? loadingMoreBucket;
  final String searchQuery;
  final bool isCreating;
  final Set<String> busyRecordIds;

  bool get canRead => bootstrap.permissions.healthRead;
  bool get canWrite => bootstrap.permissions.healthWrite;

  List<MedicalRecordCard> itemsFor(MedicalRecordBucket bucket) {
    return switch (bucket) {
      MedicalRecordBucket.active => activeItems,
      MedicalRecordBucket.archive => archiveItems,
    };
  }

  String? nextCursorFor(MedicalRecordBucket bucket) {
    return switch (bucket) {
      MedicalRecordBucket.active => activeNextCursor,
      MedicalRecordBucket.archive => archiveNextCursor,
    };
  }

  bool isLoadingMore(MedicalRecordBucket bucket) => loadingMoreBucket == bucket;

  PetMedicalRecordsState copyWith({
    String? petName,
    HealthBootstrapResponse? bootstrap,
    List<MedicalRecordCard>? activeItems,
    List<MedicalRecordCard>? archiveItems,
    String? activeNextCursor,
    bool clearActiveNextCursor = false,
    String? archiveNextCursor,
    bool clearArchiveNextCursor = false,
    MedicalRecordBucket? loadingMoreBucket,
    bool clearLoadingMoreBucket = false,
    String? searchQuery,
    bool? isCreating,
    Set<String>? busyRecordIds,
  }) {
    return PetMedicalRecordsState(
      petName: petName ?? this.petName,
      bootstrap: bootstrap ?? this.bootstrap,
      activeItems: activeItems ?? this.activeItems,
      archiveItems: archiveItems ?? this.archiveItems,
      activeNextCursor: clearActiveNextCursor
          ? null
          : activeNextCursor ?? this.activeNextCursor,
      archiveNextCursor: clearArchiveNextCursor
          ? null
          : archiveNextCursor ?? this.archiveNextCursor,
      loadingMoreBucket: clearLoadingMoreBucket
          ? null
          : loadingMoreBucket ?? this.loadingMoreBucket,
      searchQuery: searchQuery ?? this.searchQuery,
      isCreating: isCreating ?? this.isCreating,
      busyRecordIds: busyRecordIds ?? this.busyRecordIds,
    );
  }
}
