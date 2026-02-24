import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../core/network/models/pet_models.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../../data/health_repository_models.dart';
import 'health_controllers.dart';

final petHealthHomeProvider = FutureProvider.autoDispose
    .family<PetHealthHomeState, String>((ref, petId) async {
  final petsRepository = ref.read(petsRepositoryProvider);
  final healthRepository = ref.read(healthRepositoryProvider);

  final results = await Future.wait<Object>(<Future<Object>>[
    petsRepository.getPetById(petId),
    healthRepository.getHealthBootstrap(petId),
    healthRepository.listVetVisits(
      petId,
      query: const VetVisitListQuery(
        limit: 20,
        bucket: 'all',
        sort: 'updated_at_desc',
      ),
    ),
    healthRepository.listVaccinations(
      petId,
      query: const VaccinationListQuery(
        limit: 20,
        bucket: 'all',
        sort: 'updated_at_desc',
      ),
    ),
    healthRepository.listProcedures(
      petId,
      query: const ProcedureListQuery(
        limit: 20,
        bucket: 'all',
        sort: 'updated_at_desc',
      ),
    ),
    healthRepository.listMedicalRecords(
      petId,
      query: const MedicalRecordListQuery(
        limit: 20,
        bucket: 'all',
        sort: 'updated_at_desc',
      ),
    ),
  ]);

  final pet = results[0] as Pet;
  final bootstrap = results[1] as HealthBootstrapResponse;
  final vetVisits = results[2] as VetVisitListResponse;
  final vaccinations = results[3] as VaccinationListResponse;
  final procedures = results[4] as ProcedureListResponse;
  final medicalRecords = results[5] as MedicalRecordListResponse;

  return PetHealthHomeState(
    petName: pet.name,
    canRead: bootstrap.permissions.healthRead,
    canWrite: bootstrap.permissions.healthWrite,
    sections: <PetHealthHomeSectionState>[
      PetHealthHomeSectionState(
        type: PetHealthSectionType.vetVisits,
        countLabel: _countLabel(vetVisits.items.length, vetVisits.nextCursor),
      ),
      PetHealthHomeSectionState(
        type: PetHealthSectionType.vaccinations,
        countLabel: _countLabel(
          vaccinations.items.length,
          vaccinations.nextCursor,
        ),
      ),
      PetHealthHomeSectionState(
        type: PetHealthSectionType.procedures,
        countLabel: _countLabel(
          procedures.items.length,
          procedures.nextCursor,
        ),
      ),
      PetHealthHomeSectionState(
        type: PetHealthSectionType.medicalRecords,
        countLabel: _countLabel(
          medicalRecords.items.length,
          medicalRecords.nextCursor,
        ),
      ),
    ],
  );
});

enum PetHealthSectionType {
  vetVisits,
  vaccinations,
  procedures,
  medicalRecords,
}

class PetHealthHomeState {
  const PetHealthHomeState({
    required this.petName,
    required this.canRead,
    required this.canWrite,
    required this.sections,
  });

  final String petName;
  final bool canRead;
  final bool canWrite;
  final List<PetHealthHomeSectionState> sections;
}

class PetHealthHomeSectionState {
  const PetHealthHomeSectionState({
    required this.type,
    required this.countLabel,
  });

  final PetHealthSectionType type;
  final String countLabel;
}

String _countLabel(int count, String? nextCursor) {
  if (count == 0) {
    return 'Пока пусто';
  }

  if (nextCursor != null && nextCursor.isNotEmpty) {
    return '20+ записей';
  }

  return '$count ${_recordsWord(count)}';
}

String _recordsWord(int value) {
  final mod10 = value % 10;
  final mod100 = value % 100;

  if (mod10 == 1 && mod100 != 11) {
    return 'запись';
  }

  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'записи';
  }

  return 'записей';
}
