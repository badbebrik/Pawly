import '../../../../core/network/models/health_models.dart' as network;
import '../../models/document_item.dart';
import '../../models/documents_page_result.dart';

DocumentItem documentItemFromNetwork(network.PetDocument document) {
  return DocumentItem(
    id: document.id,
    fileId: document.fileId,
    fileName: document.fileName,
    fileType: document.fileType,
    downloadUrl: document.downloadUrl,
    previewUrl: document.previewUrl,
    addedAt: document.addedAt,
    addedByUserId: document.addedByUserId,
    entityType: document.entityType,
    entityId: document.entityId,
  );
}

DocumentsPageResult documentsPageResultFromNetwork(
  network.PetDocumentsListResponse response,
) {
  return DocumentsPageResult(
    items: response.items.map(documentItemFromNetwork).toList(growable: false),
    nextCursor: response.nextCursor,
  );
}
