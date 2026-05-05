import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/health_models.dart' as api;
import '../../../../core/network/models/pet_models.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../models/health_models.dart';
import '../../models/shared/health_inputs.dart';
import '../../models/vaccinations/vaccination_inputs.dart';
import '../../shared/mappers/health_mappers.dart';
import '../../states/vaccinations/vaccinations_state.dart';
import '../health_dependencies.dart';

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
      .read(vaccinationsRepositoryProvider)
      .getVaccination(args.petId, args.vaccinationId)
      .then(mapVaccination);
});

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
          await ref.read(vaccinationsRepositoryProvider).listVaccinations(
                _petId,
                query: _queryFor(
                  bucket,
                  cursor: cursor,
                  searchQuery: current.searchQuery,
                ),
              );
      final items =
          response.items.map(mapVaccinationCard).toList(growable: false);
      state = AsyncData(switch (bucket) {
        VaccinationBucket.planned => current.copyWith(
            plannedItems: <VaccinationCard>[
              ...current.plannedItems,
              ...items,
            ],
            plannedNextCursor: response.nextCursor,
            clearLoadingMoreBucket: true,
          ),
        VaccinationBucket.history => current.copyWith(
            historyItems: <VaccinationCard>[
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

  Future<void> createVaccination({
    required UpsertVaccinationInput input,
  }) async {
    final current = state.asData?.value;
    if (current == null || current.isCreating) {
      return;
    }

    state = AsyncData(current.copyWith(isCreating: true));

    try {
      await ref.read(vaccinationsRepositoryProvider).createVaccination(
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
          await ref.read(vaccinationsRepositoryProvider).getVaccination(
                _petId,
                vaccinationId,
              );
      final updated =
          await ref.read(vaccinationsRepositoryProvider).updateVaccination(
                _petId,
                vaccinationId,
                input: _copyVaccination(
                  mapVaccination(vaccination),
                  status: 'COMPLETED',
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
      return mapVaccination(updated);
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
          await ref.read(vaccinationsRepositoryProvider).updateVaccination(
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
      return mapVaccination(updated);
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
          await ref.read(vaccinationsRepositoryProvider).updateVaccination(
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
      return mapVaccination(updated);
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
      await ref.read(vaccinationsRepositoryProvider).deleteVaccination(
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
      ref.read(healthHomeRepositoryProvider).getHealthBootstrap(_petId),
      ref.read(vaccinationsRepositoryProvider).listVaccinations(
            _petId,
            query: _queryFor(VaccinationBucket.planned),
          ),
      ref.read(vaccinationsRepositoryProvider).listVaccinations(
            _petId,
            query: _queryFor(VaccinationBucket.history),
          ),
    ]);

    final pet = results[0] as Pet;
    final bootstrap = results[1] as api.HealthBootstrapResponse;
    final planned = results[2] as api.VaccinationListResponse;
    final history = results[3] as api.VaccinationListResponse;

    return PetVaccinationsState(
      petName: pet.name,
      bootstrap: mapHealthBootstrap(bootstrap),
      plannedItems:
          planned.items.map(mapVaccinationCard).toList(growable: false),
      historyItems:
          history.items.map(mapVaccinationCard).toList(growable: false),
      plannedNextCursor: planned.nextCursor,
      historyNextCursor: history.nextCursor,
      loadingMoreBucket: null,
      searchQuery: '',
      isCreating: false,
      busyVaccinationIds: <String>{},
    );
  }

  Future<PetVaccinationsState> _reloadLists(
    PetVaccinationsState current,
  ) async {
    final results = await Future.wait<Object>(<Future<Object>>[
      ref.read(vaccinationsRepositoryProvider).listVaccinations(
            _petId,
            query: _queryFor(
              VaccinationBucket.planned,
              searchQuery: current.searchQuery,
            ),
          ),
      ref.read(vaccinationsRepositoryProvider).listVaccinations(
            _petId,
            query: _queryFor(
              VaccinationBucket.history,
              searchQuery: current.searchQuery,
            ),
          ),
    ]);

    final planned = results[0] as api.VaccinationListResponse;
    final history = results[1] as api.VaccinationListResponse;

    return current.copyWith(
      plannedItems:
          planned.items.map(mapVaccinationCard).toList(growable: false),
      historyItems:
          history.items.map(mapVaccinationCard).toList(growable: false),
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
    String? searchQuery,
  }) {
    return VaccinationListQuery(
      cursor: cursor,
      limit: 20,
      searchQuery: searchQuery?.isEmpty == true ? null : searchQuery,
      status: switch (bucket) {
        VaccinationBucket.planned => 'PLANNED',
        VaccinationBucket.history => 'COMPLETED',
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
      targets: vaccination.targets
          .map((target) => HealthDictionaryRefInput(id: target.id))
          .toList(growable: false),
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
