import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/document_item.dart';

bool openRelatedDocumentEntity(
  BuildContext context, {
  required String petId,
  required DocumentItem document,
}) {
  final normalizedType = document.entityType.trim().toLowerCase();

  switch (normalizedType) {
    case 'log':
      context.pushNamed(
        'petLogDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'logId': document.entityId,
        },
      );
      return true;
    case 'vet_visit':
      context.pushNamed(
        'petVetVisitDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'visitId': document.entityId,
        },
      );
      return true;
    case 'vaccination':
      context.pushNamed(
        'petVaccinationDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'vaccinationId': document.entityId,
        },
      );
      return true;
    case 'procedure':
      context.pushNamed(
        'petProcedureDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'procedureId': document.entityId,
        },
      );
      return true;
    case 'medical_record':
      context.pushNamed(
        'petMedicalRecordDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'recordId': document.entityId,
        },
      );
      return true;
  }

  return false;
}
