import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/health_models.dart' as api;
import '../../../../core/network/models/pet_models.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../models/health_models.dart';
import '../../models/medical_records/medical_record_inputs.dart';
import '../../shared/mappers/health_mappers.dart';
import '../../states/medical_records/medical_records_state.dart';
import '../health_dependencies.dart';

final petMedicalRecordsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetMedicalRecordsController, PetMedicalRecordsState, String>(
  PetMedicalRecordsController.new,
);

final petMedicalRecordDetailsProvider =
    FutureProvider.autoDispose.family<MedicalRecord, PetMedicalRecordRef>((
  ref,
  args,
) {
  return ref
      .read(medicalRecordsRepositoryProvider)
      .getMedicalRecord(
        args.petId,
        args.recordId,
      )
      .then(mapMedicalRecord);
});

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
          await ref.read(medicalRecordsRepositoryProvider).listMedicalRecords(
                _petId,
                query: _queryFor(
                  bucket,
                  cursor: cursor,
                  searchQuery: current.searchQuery,
                ),
              );
      final items =
          response.items.map(mapMedicalRecordCard).toList(growable: false);
      state = AsyncData(switch (bucket) {
        MedicalRecordBucket.active => current.copyWith(
            activeItems: <MedicalRecordCard>[
              ...current.activeItems,
              ...items,
            ],
            activeNextCursor: response.nextCursor,
            clearLoadingMoreBucket: true,
          ),
        MedicalRecordBucket.archive => current.copyWith(
            archiveItems: <MedicalRecordCard>[
              ...current.archiveItems,
              ...items,
            ],
            archiveNextCursor: response.nextCursor,
            clearLoadingMoreBucket: true,
          ),
      });
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
      await ref.read(medicalRecordsRepositoryProvider).createMedicalRecord(
            _petId,
            input: input,
          );
      state = AsyncData(
        await _reloadLists(current.copyWith(isCreating: false)),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isCreating: false));
      rethrow;
    }
  }

  Future<void> setSearchQuery(String value) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final query = value.trim();
    if (query == current.searchQuery) {
      return;
    }

    try {
      state = AsyncData(
        await _reloadLists(current.copyWith(searchQuery: query)),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
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
          await ref.read(medicalRecordsRepositoryProvider).updateMedicalRecord(
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
      return mapMedicalRecord(updated);
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          busyRecordIds: Set<String>.from(current.busyRecordIds)
            ..remove(recordId),
        ),
      );
      rethrow;
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
      await ref.read(medicalRecordsRepositoryProvider).deleteMedicalRecord(
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
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          busyRecordIds: Set<String>.from(current.busyRecordIds)
            ..remove(recordId),
        ),
      );
      rethrow;
    }
  }

  Future<PetMedicalRecordsState> _loadInitialState() async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(petsRepositoryProvider).getPetById(_petId),
      ref.read(healthHomeRepositoryProvider).getHealthBootstrap(_petId),
      ref.read(medicalRecordsRepositoryProvider).listMedicalRecords(
            _petId,
            query: _queryFor(MedicalRecordBucket.active),
          ),
      ref.read(medicalRecordsRepositoryProvider).listMedicalRecords(
            _petId,
            query: _queryFor(MedicalRecordBucket.archive),
          ),
    ]);

    final pet = results[0] as Pet;
    final bootstrap = results[1] as api.HealthBootstrapResponse;
    final active = results[2] as api.MedicalRecordListResponse;
    final archive = results[3] as api.MedicalRecordListResponse;

    return PetMedicalRecordsState(
      petName: pet.name,
      bootstrap: mapHealthBootstrap(bootstrap),
      activeItems:
          active.items.map(mapMedicalRecordCard).toList(growable: false),
      archiveItems:
          archive.items.map(mapMedicalRecordCard).toList(growable: false),
      activeNextCursor: active.nextCursor,
      archiveNextCursor: archive.nextCursor,
      loadingMoreBucket: null,
      searchQuery: '',
      isCreating: false,
      busyRecordIds: <String>{},
    );
  }

  Future<PetMedicalRecordsState> _reloadLists(
    PetMedicalRecordsState current,
  ) async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(medicalRecordsRepositoryProvider).listMedicalRecords(
            _petId,
            query: _queryFor(
              MedicalRecordBucket.active,
              searchQuery: current.searchQuery,
            ),
          ),
      ref.read(medicalRecordsRepositoryProvider).listMedicalRecords(
            _petId,
            query: _queryFor(
              MedicalRecordBucket.archive,
              searchQuery: current.searchQuery,
            ),
          ),
    ]);

    final active = results[0] as api.MedicalRecordListResponse;
    final archive = results[1] as api.MedicalRecordListResponse;

    return current.copyWith(
      activeItems:
          active.items.map(mapMedicalRecordCard).toList(growable: false),
      archiveItems:
          archive.items.map(mapMedicalRecordCard).toList(growable: false),
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
    String? searchQuery,
  }) {
    return MedicalRecordListQuery(
      cursor: cursor,
      limit: 20,
      searchQuery: searchQuery?.isEmpty == true ? null : searchQuery,
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
