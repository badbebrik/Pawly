import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../core/network/models/pet_models.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../../data/health_repository_models.dart';
import 'health_controllers.dart';

final petVetVisitsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetVetVisitsController, PetVetVisitsState, String>(
  PetVetVisitsController.new,
);

final petVetVisitDetailsProvider =
    FutureProvider.autoDispose.family<VetVisit, PetVetVisitRef>((ref, args) {
  return ref.read(healthRepositoryProvider).getVetVisit(
        args.petId,
        args.visitId,
      );
});

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
      final response = await ref.read(healthRepositoryProvider).listVetVisits(
            _petId,
            query: _queryFor(
              bucket,
              cursor: cursor,
              searchQuery: current.searchQuery,
            ),
          );
      state = AsyncData(
        switch (bucket) {
          VetVisitBucket.upcoming => current.copyWith(
              upcomingItems: <VetVisitCard>[
                ...current.upcomingItems,
                ...response.items,
              ],
              upcomingNextCursor: response.nextCursor,
              clearLoadingMoreBucket: true,
            ),
          VetVisitBucket.history => current.copyWith(
              historyItems: <VetVisitCard>[
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
      visit = await ref.read(healthRepositoryProvider).createVetVisit(
            _petId,
            input: input,
          );
    } catch (error, stackTrace) {
      state = AsyncData(current.copyWith(isCreating: false));
      Error.throwWithStackTrace(error, stackTrace);
    }

    var relatedLogsLinked = true;
    for (final logId in input.relatedLogIds) {
      try {
        await ref.read(healthRepositoryProvider).linkLogToVetVisit(
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
      final updated = await ref.read(healthRepositoryProvider).updateVetVisit(
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
      return updated;
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
      await ref.read(healthRepositoryProvider).deleteVetVisit(
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
  }) {
    return ref.read(healthRepositoryProvider).linkLogToVetVisit(
          _petId,
          visitId,
          logId: logId,
        );
  }

  Future<void> unlinkLogFromVisit({
    required String visitId,
    required String logId,
  }) {
    return ref.read(healthRepositoryProvider).unlinkLogFromVetVisit(
          _petId,
          visitId,
          logId: logId,
        );
  }

  Future<PetVetVisitsState> _loadInitialState() async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(petsRepositoryProvider).getPetById(_petId),
      ref.read(healthRepositoryProvider).getHealthBootstrap(_petId),
      ref.read(healthRepositoryProvider).listVetVisits(
            _petId,
            query: _queryFor(VetVisitBucket.upcoming),
          ),
      ref.read(healthRepositoryProvider).listVetVisits(
            _petId,
            query: _queryFor(VetVisitBucket.history),
          ),
    ]);

    final pet = results[0] as Pet;
    final bootstrap = results[1] as HealthBootstrapResponse;
    final upcoming = results[2] as VetVisitListResponse;
    final history = results[3] as VetVisitListResponse;

    return PetVetVisitsState(
      petName: pet.name,
      bootstrap: bootstrap,
      upcomingItems: upcoming.items,
      historyItems: history.items,
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
      ref.read(healthRepositoryProvider).listVetVisits(
            _petId,
            query: _queryFor(
              VetVisitBucket.upcoming,
              searchQuery: current.searchQuery,
            ),
          ),
      ref.read(healthRepositoryProvider).listVetVisits(
            _petId,
            query: _queryFor(
              VetVisitBucket.history,
              searchQuery: current.searchQuery,
            ),
          ),
    ]);

    final upcoming = results[0] as VetVisitListResponse;
    final history = results[1] as VetVisitListResponse;

    return current.copyWith(
      upcomingItems: upcoming.items,
      historyItems: history.items,
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
