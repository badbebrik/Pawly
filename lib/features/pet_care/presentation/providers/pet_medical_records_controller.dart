import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../core/network/models/pet_models.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../../data/health_repository_models.dart';
import 'health_controllers.dart';

final petMedicalRecordsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetMedicalRecordsController, PetMedicalRecordsState, String>(
  PetMedicalRecordsController.new,
);

final petMedicalRecordDetailsProvider =
    FutureProvider.autoDispose.family<MedicalRecord, PetMedicalRecordRef>((
  ref,
  args,
) {
  return ref.read(healthRepositoryProvider).getMedicalRecord(
        args.petId,
        args.recordId,
      );
});

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
      isCreating: isCreating ?? this.isCreating,
      busyRecordIds: busyRecordIds ?? this.busyRecordIds,
    );
  }
}

class PetMedicalRecordsController
    extends AsyncNotifier<PetMedicalRecordsState> {
  PetMedicalRecordsController(this._petId);

  final String _petId;

  @override
  Future<PetMedicalRecordsState> build() {
    return _loadInitialState();
  }

  Future<void> reload() async {
    final current = state.asData?.value;
    state = const AsyncLoading();
    try {
      state = AsyncData(
        current == null
            ? await _loadInitialState()
            : await _reloadLists(current),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> loadMore(MedicalRecordBucket bucket) async {
    final current = state.asData?.value;
    final cursor = current?.nextCursorFor(bucket);
    if (current == null ||
        current.isLoadingMore(bucket) ||
        cursor == null ||
        cursor.isEmpty) {
      return;
    }

    state = AsyncData(current.copyWith(loadingMoreBucket: bucket));

    try {
      final response =
          await ref.read(healthRepositoryProvider).listMedicalRecords(
                _petId,
                query: _queryFor(bucket, cursor: cursor),
              );
      state = AsyncData(
        switch (bucket) {
          MedicalRecordBucket.active => current.copyWith(
              activeItems: <MedicalRecordCard>[
                ...current.activeItems,
                ...response.items,
              ],
              activeNextCursor: response.nextCursor,
              clearLoadingMoreBucket: true,
            ),
          MedicalRecordBucket.archive => current.copyWith(
              archiveItems: <MedicalRecordCard>[
                ...current.archiveItems,
                ...response.items,
              ],
              archiveNextCursor: response.nextCursor,
              clearLoadingMoreBucket: true,
            ),
        },
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> createMedicalRecord({
    required UpsertMedicalRecordInput input,
  }) async {
    final current = state.asData?.value;
    if (current == null || current.isCreating) {
      return;
    }

    state = AsyncData(current.copyWith(isCreating: true));

    try {
      await ref.read(healthRepositoryProvider).createMedicalRecord(
            _petId,
            input: input,
          );
      state = AsyncData(
        await _reloadLists(current.copyWith(isCreating: false)),
      );
    } catch (error, stackTrace) {
      state = AsyncData(current.copyWith(isCreating: false));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<MedicalRecord> updateMedicalRecord({
    required String recordId,
    required UpsertMedicalRecordInput input,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список медкарты еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyRecordIds: <String>{...current.busyRecordIds, recordId},
      ),
    );

    try {
      final updated =
          await ref.read(healthRepositoryProvider).updateMedicalRecord(
                _petId,
                recordId,
                input: input,
              );
      state = AsyncData(
        await _reloadLists(
          current.copyWith(
            busyRecordIds: Set<String>.from(current.busyRecordIds)
              ..remove(recordId),
          ),
        ),
      );
      return updated;
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyRecordIds: Set<String>.from(current.busyRecordIds)
            ..remove(recordId),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteMedicalRecord({
    required String recordId,
    required int rowVersion,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список медкарты еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyRecordIds: <String>{...current.busyRecordIds, recordId},
      ),
    );

    try {
      await ref.read(healthRepositoryProvider).deleteMedicalRecord(
            _petId,
            recordId,
            rowVersion: rowVersion,
          );
      state = AsyncData(
        await _reloadLists(
          current.copyWith(
            busyRecordIds: Set<String>.from(current.busyRecordIds)
              ..remove(recordId),
          ),
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyRecordIds: Set<String>.from(current.busyRecordIds)
            ..remove(recordId),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<PetMedicalRecordsState> _loadInitialState() async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(petsRepositoryProvider).getPetById(_petId),
      ref.read(healthRepositoryProvider).getHealthBootstrap(_petId),
      ref.read(healthRepositoryProvider).listMedicalRecords(
            _petId,
            query: _queryFor(MedicalRecordBucket.active),
          ),
      ref.read(healthRepositoryProvider).listMedicalRecords(
            _petId,
            query: _queryFor(MedicalRecordBucket.archive),
          ),
    ]);

    final pet = results[0] as Pet;
    final bootstrap = results[1] as HealthBootstrapResponse;
    final active = results[2] as MedicalRecordListResponse;
    final archive = results[3] as MedicalRecordListResponse;

    return PetMedicalRecordsState(
      petName: pet.name,
      bootstrap: bootstrap,
      activeItems: active.items,
      archiveItems: archive.items,
      activeNextCursor: active.nextCursor,
      archiveNextCursor: archive.nextCursor,
      loadingMoreBucket: null,
      isCreating: false,
      busyRecordIds: <String>{},
    );
  }

  Future<PetMedicalRecordsState> _reloadLists(
    PetMedicalRecordsState current,
  ) async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(healthRepositoryProvider).listMedicalRecords(
            _petId,
            query: _queryFor(MedicalRecordBucket.active),
          ),
      ref.read(healthRepositoryProvider).listMedicalRecords(
            _petId,
            query: _queryFor(MedicalRecordBucket.archive),
          ),
    ]);

    final active = results[0] as MedicalRecordListResponse;
    final archive = results[1] as MedicalRecordListResponse;

    return current.copyWith(
      activeItems: active.items,
      archiveItems: archive.items,
      activeNextCursor: active.nextCursor,
      archiveNextCursor: archive.nextCursor,
      isCreating: false,
      clearLoadingMoreBucket: true,
      busyRecordIds: <String>{},
    );
  }

  MedicalRecordListQuery _queryFor(
    MedicalRecordBucket bucket, {
    String? cursor,
  }) {
    return MedicalRecordListQuery(
      cursor: cursor,
      limit: 20,
      bucket: switch (bucket) {
        MedicalRecordBucket.active => 'active',
        MedicalRecordBucket.archive => 'archive',
      },
      sort: switch (bucket) {
        MedicalRecordBucket.active => 'started_at_desc',
        MedicalRecordBucket.archive => 'updated_at_desc',
      },
    );
  }
}
