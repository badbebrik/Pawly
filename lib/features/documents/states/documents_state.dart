import '../models/document_item.dart';

enum DocumentsKindFilter {
  all('Все', null),
  images('Фото', 'image'),
  pdf('PDF', 'pdf');

  const DocumentsKindFilter(this.label, this.queryValue);

  final String label;
  final String? queryValue;
}

enum DocumentsEntityFilter {
  all('Все сущности', null),
  logs('Записи', 'log'),
  visits('Визиты', 'vet_visit'),
  vaccinations('Вакцинации', 'vaccination'),
  procedures('Процедуры', 'procedure'),
  medicalRecords('Медкарта', 'medical_record');

  const DocumentsEntityFilter(this.label, this.queryValue);

  final String label;
  final String? queryValue;
}

class DocumentsState {
  const DocumentsState({
    required this.items,
    required this.searchQuery,
    required this.entityFilter,
    required this.kindFilter,
    required this.renamingDocumentIds,
    this.nextCursor,
    this.isLoadingMore = false,
  });

  factory DocumentsState.initial() {
    return const DocumentsState(
      items: <DocumentItem>[],
      searchQuery: '',
      entityFilter: DocumentsEntityFilter.all,
      kindFilter: DocumentsKindFilter.all,
      renamingDocumentIds: <String>{},
    );
  }

  final List<DocumentItem> items;
  final String searchQuery;
  final DocumentsEntityFilter entityFilter;
  final DocumentsKindFilter kindFilter;
  final Set<String> renamingDocumentIds;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get isEmpty => items.isEmpty;
  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  DocumentsState copyWith({
    List<DocumentItem>? items,
    String? searchQuery,
    DocumentsEntityFilter? entityFilter,
    DocumentsKindFilter? kindFilter,
    Set<String>? renamingDocumentIds,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
  }) {
    return DocumentsState(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      entityFilter: entityFilter ?? this.entityFilter,
      kindFilter: kindFilter ?? this.kindFilter,
      renamingDocumentIds: renamingDocumentIds ?? this.renamingDocumentIds,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
