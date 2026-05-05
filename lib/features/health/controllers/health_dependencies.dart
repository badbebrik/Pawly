import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../shared/attachments/data/attachment_upload_service.dart';
import '../../shared/attachments/data/attachment_upload_service_provider.dart'
    as shared_attachments;
import '../data/home/health_home_repository.dart';
import '../data/medical_records/medical_records_repository.dart';
import '../data/procedures/procedures_repository.dart';
import '../data/schedule/health_schedule_repository.dart';
import '../data/vaccinations/vaccinations_repository.dart';
import '../data/vet_visits/vet_visits_repository.dart';

final healthScheduleRepositoryProvider =
    Provider<HealthScheduleRepository>((ref) {
  final healthApiClient = ref.watch(healthApiClientProvider);
  return HealthScheduleRepository(healthApiClient: healthApiClient);
});

final healthHomeRepositoryProvider = Provider<HealthHomeRepository>((ref) {
  final healthApiClient = ref.watch(healthApiClientProvider);
  return HealthHomeRepository(healthApiClient: healthApiClient);
});

final vetVisitsRepositoryProvider = Provider<VetVisitsRepository>((ref) {
  final healthApiClient = ref.watch(healthApiClientProvider);
  return VetVisitsRepository(healthApiClient: healthApiClient);
});

final vaccinationsRepositoryProvider = Provider<VaccinationsRepository>((ref) {
  final healthApiClient = ref.watch(healthApiClientProvider);
  return VaccinationsRepository(healthApiClient: healthApiClient);
});

final proceduresRepositoryProvider = Provider<ProceduresRepository>((ref) {
  final healthApiClient = ref.watch(healthApiClientProvider);
  return ProceduresRepository(healthApiClient: healthApiClient);
});

final medicalRecordsRepositoryProvider =
    Provider<MedicalRecordsRepository>((ref) {
  final healthApiClient = ref.watch(healthApiClientProvider);
  return MedicalRecordsRepository(healthApiClient: healthApiClient);
});

final attachmentUploadServiceProvider = Provider<AttachmentUploadService>(
  (ref) => ref.watch(shared_attachments.attachmentUploadServiceProvider),
);
