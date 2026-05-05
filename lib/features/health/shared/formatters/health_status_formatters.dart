import 'package:flutter/material.dart';

import '../../models/health_models.dart';
import '../../../../design_system/design_system.dart';

String formatVetVisitStatusLabel(String status) {
  return switch (status) {
    'PLANNED' => 'Запланирован',
    'COMPLETED' => 'Завершен',
    _ => status,
  };
}

PawlyBadgeTone vetVisitStatusTone(String status) {
  return switch (status) {
    'PLANNED' => PawlyBadgeTone.info,
    'COMPLETED' => PawlyBadgeTone.success,
    _ => PawlyBadgeTone.neutral,
  };
}

String formatVetVisitTypeLabel(String type) {
  return switch (type) {
    'CHECKUP' => 'Осмотр',
    'SYMPTOM' => 'Симптомы',
    'FOLLOW_UP' => 'Повторный прием',
    'VACCINATION' => 'Вакцинация',
    'PROCEDURE' => 'Процедура',
    'OTHER' => 'Другое',
    _ => type,
  };
}

String formatVetVisitTitle(String? title, String visitType) {
  final trimmed = title?.trim() ?? '';
  return trimmed.isEmpty ? formatVetVisitTypeLabel(visitType) : trimmed;
}

String formatProcedureStatusLabel(String status) {
  return switch (status) {
    'PLANNED' => 'Запланирована',
    'COMPLETED' => 'Выполнена',
    _ => status,
  };
}

PawlyBadgeTone procedureStatusTone(String status) {
  return switch (status) {
    'PLANNED' => PawlyBadgeTone.info,
    'COMPLETED' => PawlyBadgeTone.success,
    _ => PawlyBadgeTone.neutral,
  };
}

String formatProcedureTypeItemLabel(HealthDictionaryItem? item) {
  return item?.name ?? 'Тип не указан';
}

String formatVaccinationStatusLabel(String status) {
  return switch (status) {
    'PLANNED' => 'Запланирована',
    'COMPLETED' => 'Выполнена',
    _ => status,
  };
}

PawlyBadgeTone vaccinationStatusTone(String status) {
  return switch (status) {
    'PLANNED' => PawlyBadgeTone.info,
    'COMPLETED' => PawlyBadgeTone.success,
    _ => PawlyBadgeTone.neutral,
  };
}

Color vaccinationStatusColor(String status) {
  return switch (status) {
    'PLANNED' => const Color(0xFF2B7FFF),
    'COMPLETED' => const Color(0xFF1C8D62),
    _ => const Color(0xFF94A3B8),
  };
}

String formatMedicalRecordStatusLabel(String status) {
  return switch (status) {
    'ACTIVE' => 'Активна',
    'RESOLVED' => 'Закрыта',
    _ => status,
  };
}

PawlyBadgeTone medicalRecordStatusTone(String status) {
  return switch (status) {
    'ACTIVE' => PawlyBadgeTone.info,
    'RESOLVED' => PawlyBadgeTone.success,
    _ => PawlyBadgeTone.neutral,
  };
}

String formatMedicalRecordTypeItemLabel(HealthDictionaryItem? item) {
  return item?.name ?? 'Тип не указан';
}
