import 'document_item.dart';

class DocumentsPageResult {
  const DocumentsPageResult({
    required this.items,
    this.nextCursor,
  });

  final List<DocumentItem> items;
  final String? nextCursor;
}
