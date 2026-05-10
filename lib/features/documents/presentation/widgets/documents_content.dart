import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../pets/models/pet_access_policy.dart';
import '../../../shared/attachments/models/attachment_viewer_item.dart';
import '../../models/document_item.dart';
import '../../shared/formatters/document_formatters.dart';
import '../../shared/utils/document_permissions.dart';
import '../../states/documents_state.dart';
import 'document_card.dart';
import 'documents_filters.dart';
import 'documents_status_views.dart';
import 'load_more_card.dart';

class DocumentsContent extends StatelessWidget {
  const DocumentsContent({
    required this.access,
    required this.state,
    required this.searchController,
    required this.onSearchChanged,
    required this.onEntityFilterChanged,
    required this.onKindFilterChanged,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onOpenDocument,
    required this.onRenameDocument,
    required this.onOpenRelatedEntity,
    super.key,
  });

  final PetAccessPolicy access;
  final DocumentsState state;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DocumentsEntityFilter> onEntityFilterChanged;
  final ValueChanged<DocumentsKindFilter> onKindFilterChanged;
  final RefreshCallback onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<DocumentItem> onOpenDocument;
  final ValueChanged<DocumentItem> onRenameDocument;
  final ValueChanged<DocumentItem> onOpenRelatedEntity;

  @override
  Widget build(BuildContext context) {
    if (state.isEmpty) {
      return DocumentsEmptyView(
        searchController: searchController,
        selectedEntityFilter: state.entityFilter,
        selectedKindFilter: state.kindFilter,
        onSearchChanged: onSearchChanged,
        onEntityFilterChanged: onEntityFilterChanged,
        onKindFilterChanged: onKindFilterChanged,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              PawlySpacing.md,
              PawlySpacing.sm,
              PawlySpacing.md,
              0,
            ),
            sliver: SliverList.list(
              children: <Widget>[
                DocumentsFilterSection(
                  searchController: searchController,
                  selectedEntityFilter: state.entityFilter,
                  selectedKindFilter: state.kindFilter,
                  onSearchChanged: onSearchChanged,
                  onEntityFilterChanged: onEntityFilterChanged,
                  onKindFilterChanged: onKindFilterChanged,
                ),
                const SizedBox(height: PawlySpacing.md),
                if (!access.healthWrite && !access.logWrite) ...<Widget>[
                  const DocumentsReadOnlyNotice(),
                  const SizedBox(height: PawlySpacing.md),
                ],
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: PawlySpacing.md),
            sliver: SliverList.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final document = state.items[index];
                final viewerItem = AttachmentViewerItem.fromAttachment(
                  fileId: document.fileId,
                  fileType: document.fileType,
                  fileName: document.fileName,
                  previewUrl: document.previewUrl,
                  downloadUrl: document.downloadUrl,
                );
                final canRename =
                    document.id != null && canRenameDocument(access, document);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == state.items.length - 1 && !state.hasMore
                        ? 0
                        : PawlySpacing.sm,
                  ),
                  child: DocumentCard(
                    viewerItem: viewerItem,
                    entityLabel: documentEntityLabel(document.entityType),
                    meta: documentMetaLabel(document),
                    openEntityLabel:
                        documentOpenEntityLabel(document.entityType),
                    isRenaming: document.id != null &&
                        state.renamingDocumentIds.contains(document.id),
                    onOpen: () => onOpenDocument(document),
                    onRename:
                        canRename ? () => onRenameDocument(document) : null,
                    onOpenEntity: () => onOpenRelatedEntity(document),
                  ),
                );
              },
            ),
          ),
          if (state.hasMore)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                PawlySpacing.md,
                PawlySpacing.sm,
                PawlySpacing.md,
                PawlySpacing.xl,
              ),
              sliver: SliverToBoxAdapter(
                child: LoadMoreCard(
                  isLoading: state.isLoadingMore,
                  onPressed: state.isLoadingMore ? null : onLoadMore,
                ),
              ),
            ),
          if (!state.hasMore)
            const SliverToBoxAdapter(
              child: SizedBox(height: PawlySpacing.xl),
            ),
        ],
      ),
    );
  }
}
