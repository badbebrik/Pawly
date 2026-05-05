import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/health_models.dart' as api;
import '../../../../core/network/models/pet_models.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../models/health_models.dart';
import '../../models/vet_visits/vet_visit_inputs.dart';
import '../../shared/mappers/health_mappers.dart';
import '../../states/vet_visits/vet_visits_state.dart';
import '../health_dependencies.dart';

final petVetVisitsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetVetVisitsController, PetVetVisitsState, String>(
  PetVetVisitsController.new,
);

final petVetVisitDetailsProvider =
    FutureProvider.autoDispose.family<VetVisit, PetVetVisitRef>((ref, args) {
  return ref
      .read(vetVisitsRepositoryProvider)
      .getVetVisit(args.petId, args.visitId)
      .then(mapVetVisit);
});

class PetVetVisitsController extends AsyncNotifier<PetVetVisitsState> {
  PetVetVisitsController(this._petId);

  final String _petId;

  @override
  Future<PetVetVisitsState> build() {
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

  Future<void> loadMore(VetVisitBucket bucket) async {
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
          await ref.read(vetVisitsRepositoryProvider).listVetVisits(
                _petId,
                query: _queryFor(
                  bucket,
                  cursor: cursor,
                  searchQuery: current.searchQuery,
                ),
              );
      final items = response.items.map(mapVetVisitCard).toList(growable: false);
      state = AsyncData(switch (bucket) {
        VetVisitBucket.upcoming => current.copyWith(
            upcomingItems: <VetVisitCard>[
              ...current.upcomingItems,
              ...items,
            ],
            upcomingNextCursor: response.nextCursor,
            clearLoadingMoreBucket: true,
          ),
        VetVisitBucket.history => current.copyWith(
            historyItems: <VetVisitCard>[
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

  Future<VetVisitCreateResult> createVetVisit({
    required UpsertVetVisitInput input,
  }) async {
    final current = state.asData?.value;
    if (current == null || current.isCreating) {
      throw StateError('Список визитов еще не загружен.');
    }

    state = AsyncData(current.copyWith(isCreating: true));

    late final VetVisit visit;
    try {
      final created =
          await ref.read(vetVisitsRepositoryProvider).createVetVisit(
                _petId,
                input: input,
              );
      visit = mapVetVisit(created);
    } catch (error, stackTrace) {
      state = AsyncData(current.copyWith(isCreating: false));
      Error.throwWithStackTrace(error, stackTrace);
    }

    var relatedLogsLinked = true;
    for (final logId in input.relatedLogIds) {
      try {
        await ref.read(vetVisitsRepositoryProvider).linkLogToVetVisit(
              _petId,
              visit.id,
              logId: logId,
            );
      } catch (_) {
        relatedLogsLinked = false;
      }
    }

    var listReloaded = true;
    try {
      state = AsyncData(
        await _reloadLists(current.copyWith(isCreating: false)),
      );
    } catch (_) {
      listReloaded = false;
      state = AsyncData(current.copyWith(isCreating: false));
    }

    return VetVisitCreateResult(
      visit: visit,
      relatedLogsLinked: relatedLogsLinked,
      listReloaded: listReloaded,
    );
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

  Future<VetVisit> updateVetVisit({
    required String visitId,
    required UpsertVetVisitInput input,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список визитов еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyVisitIds: <String>{...current.busyVisitIds, visitId},
      ),
    );

    try {
      final updated =
          await ref.read(vetVisitsRepositoryProvider).updateVetVisit(
                _petId,
                visitId,
                input: input,
              );
      state = AsyncData(
        await _reloadLists(
          current.copyWith(
            busyVisitIds: Set<String>.from(current.busyVisitIds)
              ..remove(visitId),
          ),
        ),
      );
      return mapVetVisit(updated);
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyVisitIds: Set<String>.from(current.busyVisitIds)..remove(visitId),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteVetVisit({
    required String visitId,
    required int rowVersion,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список визитов еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyVisitIds: <String>{...current.busyVisitIds, visitId},
      ),
    );

    try {
      await ref.read(vetVisitsRepositoryProvider).deleteVetVisit(
            _petId,
            visitId,
            rowVersion: rowVersion,
          );
      state = AsyncData(
        await _reloadLists(
          current.copyWith(
            busyVisitIds: Set<String>.from(current.busyVisitIds)
              ..remove(visitId),
          ),
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyVisitIds: Set<String>.from(current.busyVisitIds)..remove(visitId),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<RelatedLog> linkLogToVisit({
    required String visitId,
    required String logId,
  }) async {
    final log = await ref.read(vetVisitsRepositoryProvider).linkLogToVetVisit(
          _petId,
          visitId,
          logId: logId,
        );
    return mapRelatedLog(log);
  }

  Future<void> unlinkLogFromVisit({
    required String visitId,
    required String logId,
  }) {
    return ref.read(vetVisitsRepositoryProvider).unlinkLogFromVetVisit(
          _petId,
          visitId,
          logId: logId,
        );
  }

  Future<PetVetVisitsState> _loadInitialState() async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(petsRepositoryProvider).getPetById(_petId),
      ref.read(healthHomeRepositoryProvider).getHealthBootstrap(_petId),
      ref.read(vetVisitsRepositoryProvider).listVetVisits(
            _petId,
            query: _queryFor(VetVisitBucket.upcoming),
          ),
      ref.read(vetVisitsRepositoryProvider).listVetVisits(
            _petId,
            query: _queryFor(VetVisitBucket.history),
          ),
    ]);

    final pet = results[0] as Pet;
    final bootstrap = results[1] as api.HealthBootstrapResponse;
    final upcoming = results[2] as api.VetVisitListResponse;
    final history = results[3] as api.VetVisitListResponse;

    return PetVetVisitsState(
      petName: pet.name,
      bootstrap: mapHealthBootstrap(bootstrap),
      upcomingItems:
          upcoming.items.map(mapVetVisitCard).toList(growable: false),
      historyItems: history.items.map(mapVetVisitCard).toList(growable: false),
      upcomingNextCursor: upcoming.nextCursor,
      historyNextCursor: history.nextCursor,
      loadingMoreBucket: null,
      searchQuery: '',
      isCreating: false,
      busyVisitIds: <String>{},
    );
  }

  Future<PetVetVisitsState> _reloadLists(PetVetVisitsState current) async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(vetVisitsRepositoryProvider).listVetVisits(
            _petId,
            query: _queryFor(
              VetVisitBucket.upcoming,
              searchQuery: current.searchQuery,
            ),
          ),
      ref.read(vetVisitsRepositoryProvider).listVetVisits(
            _petId,
            query: _queryFor(
              VetVisitBucket.history,
              searchQuery: current.searchQuery,
            ),
          ),
    ]);

    final upcoming = results[0] as api.VetVisitListResponse;
    final history = results[1] as api.VetVisitListResponse;

    return current.copyWith(
      upcomingItems:
          upcoming.items.map(mapVetVisitCard).toList(growable: false),
      historyItems: history.items.map(mapVetVisitCard).toList(growable: false),
      upcomingNextCursor: upcoming.nextCursor,
      historyNextCursor: history.nextCursor,
      isCreating: false,
      clearLoadingMoreBucket: true,
      busyVisitIds: <String>{},
    );
  }

  VetVisitListQuery _queryFor(
    VetVisitBucket bucket, {
    String? cursor,
    String? searchQuery,
  }) {
    return VetVisitListQuery(
      cursor: cursor,
      limit: 20,
      searchQuery: searchQuery?.isEmpty == true ? null : searchQuery,
      bucket: switch (bucket) {
        VetVisitBucket.upcoming => 'upcoming',
        VetVisitBucket.history => 'history',
      },
      sort: switch (bucket) {
        VetVisitBucket.upcoming => 'scheduled_at_asc',
        VetVisitBucket.history => 'updated_at_desc',
      },
    );
  }
}
