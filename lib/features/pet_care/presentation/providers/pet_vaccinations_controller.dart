import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../core/network/models/pet_models.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../../data/health_repository_models.dart';
import 'health_controllers.dart';

final petVaccinationsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetVaccinationsController, PetVaccinationsState, String>(
  PetVaccinationsController.new,
);

final petVaccinationDetailsProvider =
    FutureProvider.autoDispose.family<Vaccination, PetVaccinationRef>((
  ref,
  args,
) {
  return ref
      .read(healthRepositoryProvider)
      .getVaccination(args.petId, args.vaccinationId);
});

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
      isCreating: isCreating ?? this.isCreating,
      busyVaccinationIds: busyVaccinationIds ?? this.busyVaccinationIds,
    );
  }
}

class PetVaccinationsController extends AsyncNotifier<PetVaccinationsState> {
  PetVaccinationsController(this._petId);

  final String _petId;

  @override
  Future<PetVaccinationsState> build() {
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

  Future<void> loadMore(VaccinationBucket bucket) async {
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
          await ref.read(healthRepositoryProvider).listVaccinations(
                _petId,
                query: _queryFor(bucket, cursor: cursor),
              );
      state = AsyncData(
        switch (bucket) {
          VaccinationBucket.planned => current.copyWith(
              plannedItems: <VaccinationCard>[
                ...current.plannedItems,
                ...response.items,
              ],
              plannedNextCursor: response.nextCursor,
              clearLoadingMoreBucket: true,
            ),
          VaccinationBucket.history => current.copyWith(
              historyItems: <VaccinationCard>[
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

  Future<void> createVaccination({
    required UpsertVaccinationInput input,
  }) async {
    final current = state.asData?.value;
    if (current == null || current.isCreating) {
      return;
    }

    state = AsyncData(current.copyWith(isCreating: true));

    try {
      await ref.read(healthRepositoryProvider).createVaccination(
            _petId,
            input: input,
          );
      final refreshed = await _reloadLists(current.copyWith(isCreating: false));
      state = AsyncData(refreshed);
    } catch (error, stackTrace) {
      state = AsyncData(current.copyWith(isCreating: false));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<Vaccination> markVaccinationDone({
    required String vaccinationId,
    required DateTime administeredAt,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список вакцинаций еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyVaccinationIds: <String>{
          ...current.busyVaccinationIds,
          vaccinationId,
        },
      ),
    );

    try {
      final vaccination =
          await ref.read(healthRepositoryProvider).getVaccination(
                _petId,
                vaccinationId,
              );
      final updated =
          await ref.read(healthRepositoryProvider).updateVaccination(
                _petId,
                vaccinationId,
                input: _copyVaccination(
                  vaccination,
                  status: 'DONE',
                  administeredAtIso: _toIsoString(administeredAt),
                ),
              );
      final refreshed = await _reloadLists(
        current.copyWith(
          busyVaccinationIds: Set<String>.from(current.busyVaccinationIds)
            ..remove(vaccinationId),
        ),
      );
      state = AsyncData(refreshed);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyVaccinationIds: Set<String>.from(current.busyVaccinationIds)
            ..remove(vaccinationId),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<Vaccination> setRevaccinationDate({
    required Vaccination vaccination,
    required DateTime nextDueAt,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список вакцинаций еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyVaccinationIds: <String>{
          ...current.busyVaccinationIds,
          vaccination.id,
        },
      ),
    );

    try {
      final updated =
          await ref.read(healthRepositoryProvider).updateVaccination(
                _petId,
                vaccination.id,
                input: _copyVaccination(
                  vaccination,
                  nextDueAtIso: _toIsoString(nextDueAt),
                ),
              );
      final refreshed = await _reloadLists(
        current.copyWith(
          busyVaccinationIds: Set<String>.from(current.busyVaccinationIds)
            ..remove(vaccination.id),
        ),
      );
      state = AsyncData(refreshed);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyVaccinationIds: Set<String>.from(current.busyVaccinationIds)
            ..remove(vaccination.id),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<Vaccination> updateVaccination({
    required String vaccinationId,
    required UpsertVaccinationInput input,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список вакцинаций еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyVaccinationIds: <String>{
          ...current.busyVaccinationIds,
          vaccinationId,
        },
      ),
    );

    try {
      final updated =
          await ref.read(healthRepositoryProvider).updateVaccination(
                _petId,
                vaccinationId,
                input: input,
              );
      final refreshed = await _reloadLists(
        current.copyWith(
          busyVaccinationIds: Set<String>.from(current.busyVaccinationIds)
            ..remove(vaccinationId),
        ),
      );
      state = AsyncData(refreshed);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyVaccinationIds: Set<String>.from(current.busyVaccinationIds)
            ..remove(vaccinationId),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteVaccination({
    required String vaccinationId,
    required int rowVersion,
  }) async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Список вакцинаций еще не загружен.');
    }

    state = AsyncData(
      current.copyWith(
        busyVaccinationIds: <String>{
          ...current.busyVaccinationIds,
          vaccinationId,
        },
      ),
    );

    try {
      await ref.read(healthRepositoryProvider).deleteVaccination(
            _petId,
            vaccinationId,
            rowVersion: rowVersion,
          );
      final refreshed = await _reloadLists(
        current.copyWith(
          busyVaccinationIds: Set<String>.from(current.busyVaccinationIds)
            ..remove(vaccinationId),
        ),
      );
      state = AsyncData(refreshed);
    } catch (error, stackTrace) {
      state = AsyncData(
        current.copyWith(
          busyVaccinationIds: Set<String>.from(current.busyVaccinationIds)
            ..remove(vaccinationId),
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<PetVaccinationsState> _loadInitialState() async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(petsRepositoryProvider).getPetById(_petId),
      ref.read(healthRepositoryProvider).getHealthBootstrap(_petId),
      ref.read(healthRepositoryProvider).listVaccinations(
            _petId,
            query: _queryFor(VaccinationBucket.planned),
          ),
      ref.read(healthRepositoryProvider).listVaccinations(
            _petId,
            query: _queryFor(VaccinationBucket.history),
          ),
    ]);

    final pet = results[0] as Pet;
    final bootstrap = results[1] as HealthBootstrapResponse;
    final planned = results[2] as VaccinationListResponse;
    final history = results[3] as VaccinationListResponse;

    return PetVaccinationsState(
      petName: pet.name,
      bootstrap: bootstrap,
      plannedItems: planned.items,
      historyItems: history.items,
      plannedNextCursor: planned.nextCursor,
      historyNextCursor: history.nextCursor,
      loadingMoreBucket: null,
      isCreating: false,
      busyVaccinationIds: <String>{},
    );
  }

  Future<PetVaccinationsState> _reloadLists(
    PetVaccinationsState current,
  ) async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(healthRepositoryProvider).listVaccinations(
            _petId,
            query: _queryFor(VaccinationBucket.planned),
          ),
      ref.read(healthRepositoryProvider).listVaccinations(
            _petId,
            query: _queryFor(VaccinationBucket.history),
          ),
    ]);

    final planned = results[0] as VaccinationListResponse;
    final history = results[1] as VaccinationListResponse;

    return current.copyWith(
      plannedItems: planned.items,
      historyItems: history.items,
      plannedNextCursor: planned.nextCursor,
      historyNextCursor: history.nextCursor,
      isCreating: false,
      clearLoadingMoreBucket: true,
      busyVaccinationIds: <String>{},
    );
  }

  VaccinationListQuery _queryFor(
    VaccinationBucket bucket, {
    String? cursor,
  }) {
    return VaccinationListQuery(
      cursor: cursor,
      limit: 20,
      bucket: switch (bucket) {
        VaccinationBucket.planned => 'planned',
        VaccinationBucket.history => 'history',
      },
      sort: switch (bucket) {
        VaccinationBucket.planned => 'scheduled_at_asc',
        VaccinationBucket.history => 'administered_at_desc',
      },
    );
  }

  UpsertVaccinationInput _copyVaccination(
    Vaccination vaccination, {
    String? status,
    String? administeredAtIso,
    String? nextDueAtIso,
  }) {
    return UpsertVaccinationInput(
      status: status ?? vaccination.status,
      vaccineName: vaccination.vaccineName,
      catalogMedicationId: vaccination.catalogMedicationId,
      scheduledAtIso: _toIsoString(vaccination.scheduledAt),
      administeredAtIso:
          administeredAtIso ?? _toIsoString(vaccination.administeredAt),
      nextDueAtIso: nextDueAtIso ?? _toIsoString(vaccination.nextDueAt),
      vetVisitId: vaccination.vetVisitId,
      clinicName: vaccination.clinicName,
      vetName: vaccination.vetName,
      notes: vaccination.notes,
      attachmentFileIds: vaccination.attachments
          .map((item) => item.fileId)
          .toList(growable: false),
      rowVersion: vaccination.rowVersion,
    );
  }

  String? _toIsoString(DateTime? value) => value?.toIso8601String();
}
