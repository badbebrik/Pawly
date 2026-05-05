import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/attachment_launcher.dart';
import '../../../../design_system/design_system.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../../shared/attachments/presentation/widgets/attachment_rename_dialog.dart';
import '../../controllers/documents_controller.dart';
import '../../models/document_item.dart';
import '../../shared/formatters/document_formatters.dart';
import '../../shared/utils/document_navigation.dart';
import '../widgets/documents_content.dart';
import '../widgets/documents_status_views.dart';

class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(petAccessPolicyProvider(widget.petId));

    return PawlyScreenScaffold(
      title: 'Документы',
      body: accessAsync.when(
        data: (access) {
          if (!access.documentsRead) {
            return const DocumentsNoAccessView();
          }

          final documentsAsync = ref.watch(
            documentsControllerProvider(widget.petId),
          );
          return documentsAsync.when(
            data: (state) => DocumentsContent(
              access: access,
              state: state,
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              onEntityFilterChanged: (value) {
                ref
                    .read(documentsControllerProvider(widget.petId).notifier)
                    .setEntityFilter(value);
              },
              onKindFilterChanged: (value) {
                ref
                    .read(documentsControllerProvider(widget.petId).notifier)
                    .setKindFilter(value);
              },
              onRefresh: () => ref
                  .read(documentsControllerProvider(widget.petId).notifier)
                  .reload(),
              onLoadMore: () {
                ref
                    .read(documentsControllerProvider(widget.petId).notifier)
                    .loadMore();
              },
              onOpenDocument: _openDocument,
              onRenameDocument: _renameDocument,
              onOpenRelatedEntity: _openRelatedEntity,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => DocumentsErrorView(
              message: documentErrorMessage(
                error,
                'Не удалось загрузить документы.',
              ),
              onRetry: () => ref
                  .read(documentsControllerProvider(widget.petId).notifier)
                  .reload(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => DocumentsErrorView(
          message: 'Не удалось проверить права доступа.',
          onRetry: () => ref.invalidate(petAccessPolicyProvider(widget.petId)),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      ref
          .read(documentsControllerProvider(widget.petId).notifier)
          .setSearchQuery(value);
    });
  }

  Future<void> _openDocument(DocumentItem document) {
    return openAttachmentUrl(
      context,
      fileId: document.fileId,
      fileType: document.fileType,
      fileName: _documentFileName(document),
      previewUrl: document.previewUrl,
      downloadUrl: document.downloadUrl,
    );
  }

  void _openRelatedEntity(DocumentItem document) {
    final opened = openRelatedDocumentEntity(
      context,
      petId: widget.petId,
      document: document,
    );
    if (opened) {
      return;
    }

    showPawlySnackBar(
      context,
      message: 'Для этого документа переход к сущности недоступен.',
      tone: PawlySnackBarTone.error,
    );
  }

  Future<void> _renameDocument(DocumentItem document) async {
    final documentId = document.id;
    if (documentId == null) {
      return;
    }

    final currentName = _documentFileName(document);
    final newName = await showAttachmentRenameDialog(
      context,
      initialName: currentName,
    );
    if (newName == null || newName == currentName || !mounted) {
      return;
    }

    try {
      await ref
          .read(documentsControllerProvider(widget.petId).notifier)
          .renameDocument(documentId: documentId, fileName: newName);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: documentErrorMessage(
          error,
          'Не удалось переименовать документ.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }
}

String _documentFileName(DocumentItem document) {
  final fileName = document.fileName?.trim();
  return fileName == null || fileName.isEmpty ? 'Файл' : fileName;
}
