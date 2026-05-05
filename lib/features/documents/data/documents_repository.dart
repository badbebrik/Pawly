import '../../../core/network/clients/health_api_client.dart';
import '../../../core/network/models/health_models.dart';
import '../models/document_item.dart';
import '../models/documents_page_result.dart';
import '../models/documents_query.dart';
import '../shared/mappers/document_mapper.dart';

class DocumentsRepository {
  const DocumentsRepository({
    required HealthApiClient healthApiClient,
  }) : _healthApiClient = healthApiClient;

  final HealthApiClient _healthApiClient;

  Future<DocumentsPageResult> listDocuments(
    String petId, {
    DocumentsQuery query = const DocumentsQuery(),
  }) async {
    final response = await _healthApiClient.listDocuments(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      query: query.searchQuery,
      entityType: query.entityType,
      fileType: query.fileType,
    );
    return documentsPageResultFromNetwork(response);
  }

  Future<DocumentItem> updateDocument(
    String petId,
    String documentId, {
    required String fileName,
  }) async {
    final document = await _healthApiClient.updateDocument(
      petId,
      documentId,
      UpdatePetDocumentPayload(fileName: fileName),
    );
    return documentItemFromNetwork(document);
  }
}
