import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/health_models.dart' as api;
import '../../../../core/network/models/pet_models.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../../shared/attachments/data/attachment_input.dart';
import '../../models/health_models.dart';
import '../../models/procedures/procedure_inputs.dart';
import '../../shared/mappers/health_mappers.dart';
import '../../states/procedures/procedures_state.dart';
import '../health_dependencies.dart';

final petProceduresControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetProceduresController, PetProceduresState, String>(
  PetProceduresController.new,
);

final petProcedureDetailsProvider =
    FutureProvider.autoDispose.family<Procedure, PetProcedureRef>((
  ref,
  args,
) {
  return ref
      .read(proceduresRepositoryProvider)
      .getProcedure(
        args.petId,
        args.procedureId,
      )
      .then(mapProcedure);
});

class PetProceduresController extends AsyncNotifier<PetProceduresState> {
  PetProceduresController(this._petId);

  final String _petId;

  @override
  Future<PetProceduresState> build() {
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

  Future<void> loadMore(ProcedureBucket bucket) async {
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
          await ref.read(proceduresRepositoryProvider).listProcedures(
                _petId,
                query: _queryFor(
                  bucket,
                  cursor: cursor,
                  searchQuery: current.searchQuery,
                ),
              );
      final items =
          response.items.map(mapProcedureCard).toList(growable: false);
      state = AsyncData(switch (bucket) {
        ProcedureBucket.planned => current.copyWith(
            plannedItems: <ProcedureCard>[
              ...current.plannedItems,
              ...items,
            ],
            plannedNextCursor: response.nextCursor,
            clearLoadingMoreBucket: true,
          ),
        ProcedureBucket.history => current.copyWith(
            historyItems: <ProcedureCard>[
              ...current.historyItems,
              ...items,
            ],
            historyNextCursor: response.nextCursor,
            clearLoadingMoreBucket: true,
          ),
      });
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> createProcedure({
    required UpsertProcedureInput input,
  }) async {
    final current = state.asData?.value;
    if (current == null || current.isCreating) {
      return;
    }

    state = AsyncData(current.copyWith(isCreating: true));

    try {
      await ref.read(proceduresRepositoryProvider).createProcedure(
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

  Future<Procedure> updateProcedure({
    required String procedureId,
    required UpsertProcedureInput input,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список процедур еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyProcedureIds: <String>{...current.busyProcedureIds, procedureId},
      ),
    );

    try {
      final updated =
          await ref.read(proceduresRepositoryProvider).updateProcedure(
                _petId,
                procedureId,
                input: input,
              );
      state = AsyncData(
        await _reloadLists(
          current.copyWith(
            busyProcedureIds: Set<String>.from(current.busyProcedureIds)
              ..remove(procedureId),
          ),
        ),
      );
      return mapProcedure(updated);
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyProcedureIds: Set<String>.from(current.busyProcedureIds)
            ..remove(procedureId),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<Procedure> markProcedureDone({
    required String procedureId,
    required DateTime performedAt,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список процедур еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyProcedureIds: <String>{...current.busyProcedureIds, procedureId},
      ),
    );

    try {
      final procedure =
          await ref.read(proceduresRepositoryProvider).getProcedure(
                _petId,
                procedureId,
              );
      final updated =
          await ref.read(proceduresRepositoryProvider).updateProcedure(
                _petId,
                procedureId,
                input: _copyProcedure(
                  mapProcedure(procedure),
                  status: 'COMPLETED',
                  performedAtIso: _toIsoString(performedAt),
                ),
              );
      state = AsyncData(
        await _reloadLists(
          current.copyWith(
            busyProcedureIds: Set<String>.from(current.busyProcedureIds)
              ..remove(procedureId),
          ),
        ),
      );
      return mapProcedure(updated);
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyProcedureIds: Set<String>.from(current.busyProcedureIds)
            ..remove(procedureId),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<Procedure> setNextProcedureDate({
    required Procedure procedure,
    required DateTime nextDueAt,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список процедур еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyProcedureIds: <String>{...current.busyProcedureIds, procedure.id},
      ),
    );

    try {
      final updated =
          await ref.read(proceduresRepositoryProvider).updateProcedure(
                _petId,
                procedure.id,
                input: _copyProcedure(
                  procedure,
                  nextDueAtIso: _toIsoString(nextDueAt),
                ),
              );
      state = AsyncData(
        await _reloadLists(
          current.copyWith(
            busyProcedureIds: Set<String>.from(current.busyProcedureIds)
              ..remove(procedure.id),
          ),
        ),
      );
      return mapProcedure(updated);
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyProcedureIds: Set<String>.from(current.busyProcedureIds)
            ..remove(procedure.id),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteProcedure({
    required String procedureId,
    required int rowVersion,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список процедур еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyProcedureIds: <String>{...current.busyProcedureIds, procedureId},
      ),
    );

    try {
      await ref.read(proceduresRepositoryProvider).deleteProcedure(
            _petId,
            procedureId,
            rowVersion: rowVersion,
          );
      state = AsyncData(
        await _reloadLists(
          current.copyWith(
            busyProcedureIds: Set<String>.from(current.busyProcedureIds)
              ..remove(procedureId),
          ),
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyProcedureIds: Set<String>.from(current.busyProcedureIds)
            ..remove(procedureId),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<PetProceduresState> _loadInitialState() async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(petsRepositoryProvider).getPetById(_petId),
      ref.read(healthHomeRepositoryProvider).getHealthBootstrap(_petId),
      ref.read(proceduresRepositoryProvider).listProcedures(
            _petId,
            query: _queryFor(ProcedureBucket.planned),
          ),
      ref.read(proceduresRepositoryProvider).listProcedures(
            _petId,
            query: _queryFor(ProcedureBucket.history),
          ),
    ]);

    final pet = results[0] as Pet;
    final bootstrap = results[1] as api.HealthBootstrapResponse;
    final planned = results[2] as api.ProcedureListResponse;
    final history = results[3] as api.ProcedureListResponse;

    return PetProceduresState(
      petName: pet.name,
      bootstrap: mapHealthBootstrap(bootstrap),
      plannedItems: planned.items.map(mapProcedureCard).toList(growable: false),
      historyItems: history.items.map(mapProcedureCard).toList(growable: false),
      plannedNextCursor: planned.nextCursor,
      historyNextCursor: history.nextCursor,
      loadingMoreBucket: null,
      searchQuery: '',
      isCreating: false,
      busyProcedureIds: <String>{},
    );
  }

  Future<PetProceduresState> _reloadLists(PetProceduresState current) async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(proceduresRepositoryProvider).listProcedures(
            _petId,
            query: _queryFor(
              ProcedureBucket.planned,
              searchQuery: current.searchQuery,
            ),
          ),
      ref.read(proceduresRepositoryProvider).listProcedures(
            _petId,
            query: _queryFor(
              ProcedureBucket.history,
              searchQuery: current.searchQuery,
            ),
          ),
    ]);

    final planned = results[0] as api.ProcedureListResponse;
    final history = results[1] as api.ProcedureListResponse;

    return current.copyWith(
      plannedItems: planned.items.map(mapProcedureCard).toList(growable: false),
      historyItems: history.items.map(mapProcedureCard).toList(growable: false),
      plannedNextCursor: planned.nextCursor,
      historyNextCursor: history.nextCursor,
      isCreating: false,
      clearLoadingMoreBucket: true,
      busyProcedureIds: <String>{},
    );
  }

  ProcedureListQuery _queryFor(
    ProcedureBucket bucket, {
    String? cursor,
    String? searchQuery,
  }) {
    return ProcedureListQuery(
      cursor: cursor,
      limit: 20,
      searchQuery: searchQuery?.isEmpty == true ? null : searchQuery,
      bucket: switch (bucket) {
        ProcedureBucket.planned => 'planned',
        ProcedureBucket.history => 'history',
      },
      sort: switch (bucket) {
        ProcedureBucket.planned => 'scheduled_at_asc',
        ProcedureBucket.history => 'updated_at_desc',
      },
    );
  }

  UpsertProcedureInput _copyProcedure(
    Procedure procedure, {
    String? status,
    String? performedAtIso,
    String? nextDueAtIso,
  }) {
    return UpsertProcedureInput(
      status: status ?? procedure.status,
      procedureTypeId: procedure.procedureTypeItem?.id,
      procedureTypeName:
          procedure.procedureTypeItem == null ? procedure.title : null,
      title: procedure.title,
      description: procedure.description,
      catalogMedicationId: procedure.catalogMedicationId,
      productName: procedure.productName,
      scheduledAtIso: _toIsoString(procedure.scheduledAt),
      performedAtIso: performedAtIso ?? _toIsoString(procedure.performedAt),
      nextDueAtIso: nextDueAtIso ?? _toIsoString(procedure.nextDueAt),
      vetVisitId: procedure.vetVisitId,
      notes: procedure.notes,
      attachments: procedure.attachments
          .map(
            (attachment) => AttachmentInput(
              fileId: attachment.fileId,
              fileName: attachment.fileName ?? '',
            ),
          )
          .toList(growable: false),
      rowVersion: procedure.rowVersion,
    );
  }

  String? _toIsoString(DateTime? value) => value?.toIso8601String();
}
