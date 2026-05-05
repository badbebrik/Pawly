import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/documents_repository.dart';
import '../models/document_item.dart';
import '../models/documents_query.dart';
import '../shared/formatters/document_formatters.dart';
import '../states/documents_state.dart';

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  final healthApiClient = ref.watch(healthApiClientProvider);
  return DocumentsRepository(healthApiClient: healthApiClient);
});

final documentsSummaryProvider =
    FutureProvider.autoDispose.family<String, String>((ref, petId) async {
  final response = await ref.read(documentsRepositoryProvider).listDocuments(
        petId,
        query: const DocumentsQuery(limit: 20),
      );
  return documentsCountLabel(response.items.length, response.nextCursor);
});

final documentsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<DocumentsController, DocumentsState, String>(
  DocumentsController.new,
);

class DocumentsController extends AsyncNotifier<DocumentsState> {
  static const _pageSize = 30;

  DocumentsController(this._petId);

  final String _petId;

  @override
  Future<DocumentsState> build() async {
    return _loadPage(base: DocumentsState.initial(), reset: true);
  }

  Future<void> reload() async {
    final current = state.asData?.value ?? DocumentsState.initial();
    state = const AsyncLoading<DocumentsState>();
    state = AsyncData(await _loadPage(base: current, reset: true));
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _loadPage(base: current, reset: false);
      state = AsyncData(next.copyWith(isLoadingMore: false));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }

  Future<void> setSearchQuery(String value) async {
    final current = state.asData?.value ?? DocumentsState.initial();
    final query = value.trim();
    if (query == current.searchQuery) {
      return;
    }

    state = const AsyncLoading<DocumentsState>();
    state = AsyncData(
      await _loadPage(
        base: current.copyWith(searchQuery: query, clearNextCursor: true),
        reset: true,
      ),
    );
  }

  Future<void> setEntityFilter(DocumentsEntityFilter value) async {
    final current = state.asData?.value ?? DocumentsState.initial();
    if (value == current.entityFilter) {
      return;
    }

    state = const AsyncLoading<DocumentsState>();
    state = AsyncData(
      await _loadPage(
        base: current.copyWith(entityFilter: value, clearNextCursor: true),
        reset: true,
      ),
    );
  }

  Future<void> setKindFilter(DocumentsKindFilter value) async {
    final current = state.asData?.value ?? DocumentsState.initial();
    if (value == current.kindFilter) {
      return;
    }

    state = const AsyncLoading<DocumentsState>();
    state = AsyncData(
      await _loadPage(
        base: current.copyWith(kindFilter: value, clearNextCursor: true),
        reset: true,
      ),
    );
  }

  Future<void> renameDocument({
    required String documentId,
    required String fileName,
  }) async {
    final current = state.asData?.value;
    if (current == null || current.renamingDocumentIds.contains(documentId)) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        renamingDocumentIds: <String>{
          ...current.renamingDocumentIds,
          documentId,
        },
      ),
    );

    try {
      final updated =
          await ref.read(documentsRepositoryProvider).updateDocument(
                _petId,
                documentId,
                fileName: fileName,
              );
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          items: _replaceDocument(latest.items, updated),
          renamingDocumentIds: _withoutId(
            latest.renamingDocumentIds,
            documentId,
          ),
        ),
      );
      ref.invalidate(documentsSummaryProvider(_petId));
    } catch (_) {
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          renamingDocumentIds: _withoutId(
            latest.renamingDocumentIds,
            documentId,
          ),
        ),
      );
      rethrow;
    }
  }

  Future<DocumentsState> _loadPage({
    required DocumentsState base,
    required bool reset,
  }) async {
    final response = await ref.read(documentsRepositoryProvider).listDocuments(
          _petId,
          query: DocumentsQuery(
            cursor: reset ? null : base.nextCursor,
            limit: _pageSize,
            searchQuery: _nonEmpty(base.searchQuery),
            entityType: base.entityFilter.queryValue,
            fileType: base.kindFilter.queryValue,
          ),
        );

    final items = reset
        ? response.items
        : <DocumentItem>[...base.items, ...response.items];
    return base.copyWith(
      items: items,
      nextCursor: response.nextCursor,
      isLoadingMore: false,
    );
  }

  String? _nonEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

List<DocumentItem> _replaceDocument(
  List<DocumentItem> items,
  DocumentItem updated,
) {
  return items
      .map((item) => item.id == updated.id ? updated : item)
      .toList(growable: false);
}

Set<String> _withoutId(Set<String> values, String id) {
  return values.where((value) => value != id).toSet();
}
