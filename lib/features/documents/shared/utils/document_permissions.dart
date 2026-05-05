import '../../../pets/models/pet_access_policy.dart';
import '../../models/document_item.dart';

bool canRenameDocument(PetAccessPolicy access, DocumentItem document) {
  if (document.entityType.trim().toUpperCase() == 'LOG') {
    return access.logWrite;
  }
  return access.healthWrite;
}
