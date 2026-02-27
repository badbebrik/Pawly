import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../core/network/models/pet_models.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../../data/health_repository_models.dart';
import 'health_controllers.dart';

final petProceduresControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetProceduresController, PetProceduresState, String>(
  PetProceduresController.new,
);

final petProcedureDetailsProvider =
    FutureProvider.autoDispose.family<Procedure, PetProcedureRef>((
  ref,
  args,
) {
  return ref.read(healthRepositoryProvider).getProcedure(
        args.petId,
        args.procedureId,
      );
});

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
      isCreating: isCreating ?? this.isCreating,
      busyProcedureIds: busyProcedureIds ?? this.busyProcedureIds,
    );
  }
}

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
      final response = await ref.read(healthRepositoryProvider).listProcedures(
            _petId,
            query: _queryFor(bucket, cursor: cursor),
          );
      state = AsyncData(
        switch (bucket) {
          ProcedureBucket.planned => current.copyWith(
              plannedItems: <ProcedureCard>[
                ...current.plannedItems,
                ...response.items,
              ],
              plannedNextCursor: response.nextCursor,
              clearLoadingMoreBucket: true,
            ),
          ProcedureBucket.history => current.copyWith(
              historyItems: <ProcedureCard>[
                ...current.historyItems,
                ...response.items,
              ],
              historyNextCursor: response.nextCursor,
              clearLoadingMoreBucket: true,
            ),
        },
      );
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
      await ref.read(healthRepositoryProvider).createProcedure(
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
      final updated = await ref.read(healthRepositoryProvider).updateProcedure(
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
      return updated;
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
      await ref.read(healthRepositoryProvider).deleteProcedure(
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
      ref.read(healthRepositoryProvider).getHealthBootstrap(_petId),
      ref.read(healthRepositoryProvider).listProcedures(
            _petId,
            query: _queryFor(ProcedureBucket.planned),
          ),
      ref.read(healthRepositoryProvider).listProcedures(
            _petId,
            query: _queryFor(ProcedureBucket.history),
          ),
    ]);

    final pet = results[0] as Pet;
    final bootstrap = results[1] as HealthBootstrapResponse;
    final planned = results[2] as ProcedureListResponse;
    final history = results[3] as ProcedureListResponse;

    return PetProceduresState(
      petName: pet.name,
      bootstrap: bootstrap,
      plannedItems: planned.items,
      historyItems: history.items,
      plannedNextCursor: planned.nextCursor,
      historyNextCursor: history.nextCursor,
      loadingMoreBucket: null,
      isCreating: false,
      busyProcedureIds: <String>{},
    );
  }

  Future<PetProceduresState> _reloadLists(PetProceduresState current) async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(healthRepositoryProvider).listProcedures(
            _petId,
            query: _queryFor(ProcedureBucket.planned),
          ),
      ref.read(healthRepositoryProvider).listProcedures(
            _petId,
            query: _queryFor(ProcedureBucket.history),
          ),
    ]);

    final planned = results[0] as ProcedureListResponse;
    final history = results[1] as ProcedureListResponse;

    return current.copyWith(
      plannedItems: planned.items,
      historyItems: history.items,
      plannedNextCursor: planned.nextCursor,
      historyNextCursor: history.nextCursor,
      isCreating: false,
      clearLoadingMoreBucket: true,
      busyProcedureIds: <String>{},
    );
  }

  ProcedureListQuery _queryFor(ProcedureBucket bucket, {String? cursor}) {
    return ProcedureListQuery(
      cursor: cursor,
      limit: 20,
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
}
