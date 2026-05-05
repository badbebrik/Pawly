class DocumentsQuery {
  const DocumentsQuery({
    this.cursor,
    this.limit = 30,
    this.searchQuery,
    this.entityType,
    this.fileType,
  });

  final String? cursor;
  final int limit;
  final String? searchQuery;
  final String? entityType;
  final String? fileType;
}
