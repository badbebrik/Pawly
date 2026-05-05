import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/health_models.dart' as api;
import '../../../../core/network/models/pet_models.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../models/medical_records/medical_record_inputs.dart';
import '../../models/procedures/procedure_inputs.dart';
import '../../models/vaccinations/vaccination_inputs.dart';
import '../../models/vet_visits/vet_visit_inputs.dart';
import '../../shared/formatters/health_count_formatter.dart';
import '../../states/home/health_home_state.dart';
import '../health_dependencies.dart';

final petHealthHomeProvider = FutureProvider.autoDispose
    .family<PetHealthHomeState, String>((ref, petId) async {
  final petsRepository = ref.read(petsRepositoryProvider);
  final healthHomeRepository = ref.read(healthHomeRepositoryProvider);
  final vetVisitsRepository = ref.read(vetVisitsRepositoryProvider);
  final vaccinationsRepository = ref.read(vaccinationsRepositoryProvider);
  final proceduresRepository = ref.read(proceduresRepositoryProvider);
  final medicalRecordsRepository = ref.read(medicalRecordsRepositoryProvider);

  final results = await Future.wait<Object>(<Future<Object>>[
    petsRepository.getPetById(petId),
    healthHomeRepository.getHealthBootstrap(petId),
    vetVisitsRepository.listVetVisits(
      petId,
      query: const VetVisitListQuery(
        limit: 20,
        bucket: 'all',
        sort: 'updated_at_desc',
      ),
    ),
    vaccinationsRepository.listVaccinations(
      petId,
      query: const VaccinationListQuery(
        limit: 20,
        bucket: 'all',
        sort: 'updated_at_desc',
      ),
    ),
    proceduresRepository.listProcedures(
      petId,
      query: const ProcedureListQuery(
        limit: 20,
        bucket: 'all',
        sort: 'updated_at_desc',
      ),
    ),
    medicalRecordsRepository.listMedicalRecords(
      petId,
      query: const MedicalRecordListQuery(
        limit: 20,
        bucket: 'active',
        sort: 'updated_at_desc',
      ),
    ),
    medicalRecordsRepository.listMedicalRecords(
      petId,
      query: const MedicalRecordListQuery(
        limit: 20,
        bucket: 'archive',
        sort: 'updated_at_desc',
      ),
    ),
  ]);

  final pet = results[0] as Pet;
  final bootstrap = results[1] as api.HealthBootstrapResponse;
  final vetVisits = results[2] as api.VetVisitListResponse;
  final vaccinations = results[3] as api.VaccinationListResponse;
  final procedures = results[4] as api.ProcedureListResponse;
  final activeMedicalRecords = results[5] as api.MedicalRecordListResponse;
  final archiveMedicalRecords = results[6] as api.MedicalRecordListResponse;

  return PetHealthHomeState(
    petName: pet.name,
    canRead: bootstrap.permissions.healthRead,
    canWrite: bootstrap.permissions.healthWrite,
    sections: <PetHealthHomeSectionState>[
      PetHealthHomeSectionState(
        type: PetHealthSectionType.vetVisits,
        countLabel: formatHealthRecordsCount(
          vetVisits.items.length,
          hasMore: hasHealthNextPage(vetVisits.nextCursor),
        ),
      ),
      PetHealthHomeSectionState(
        type: PetHealthSectionType.vaccinations,
        countLabel: formatHealthRecordsCount(
          vaccinations.items.length,
          hasMore: hasHealthNextPage(vaccinations.nextCursor),
        ),
      ),
      PetHealthHomeSectionState(
        type: PetHealthSectionType.procedures,
        countLabel: formatHealthRecordsCount(
          procedures.items.length,
          hasMore: hasHealthNextPage(procedures.nextCursor),
        ),
      ),
      PetHealthHomeSectionState(
        type: PetHealthSectionType.medicalRecords,
        countLabel: formatHealthRecordsCount(
          activeMedicalRecords.items.length +
              archiveMedicalRecords.items.length,
          hasMore: hasHealthNextPage(activeMedicalRecords.nextCursor) ||
              hasHealthNextPage(archiveMedicalRecords.nextCursor),
        ),
      ),
    ],
  );
});
