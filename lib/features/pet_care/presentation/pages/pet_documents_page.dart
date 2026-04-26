import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../core/services/attachment_launcher.dart';
import '../../../../design_system/design_system.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../../pets/models/pet_access_policy.dart';
import '../../data/health_repository_models.dart';
import '../models/attachment_kind.dart';
import '../models/attachment_viewer_item.dart';
import '../providers/health_controllers.dart';
import '../widgets/attachment_rename_dialog.dart';

class PetDocumentsPage extends ConsumerStatefulWidget {
  const PetDocumentsPage({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<PetDocumentsPage> createState() => _PetDocumentsPageState();
}

class _PetDocumentsPageState extends ConsumerState<PetDocumentsPage> {
  static const _pageSize = 30;

  final _searchController = TextEditingController();
  final List<PetDocument> _documents = <PetDocument>[];
  final Set<String> _renamingDocumentIds = <String>{};
  _DocumentsEntityFilter _selectedEntityFilter = _DocumentsEntityFilter.all;
  _DocumentsKindFilter _selectedKindFilter = _DocumentsKindFilter.all;
  Timer? _searchDebounce;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _didRequestInitialLoad = false;
  Object? _error;
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments({required bool reset}) async {
    if (_isLoadingMore) {
      return;
    }

    final cursor = reset ? null : _nextCursor;
    if (!reset && (cursor == null || cursor.isEmpty)) {
      return;
    }

    setState(() {
      if (reset) {
        _isInitialLoading = _documents.isEmpty;
        _error = null;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final response = await ref.read(healthRepositoryProvider).listDocuments(
            widget.petId,
            query: PetDocumentsQuery(
              cursor: cursor,
              limit: _pageSize,
              searchQuery: _nonEmpty(_searchController.text),
              entityType: _selectedEntityFilter.queryValue,
              fileType: _selectedKindFilter.queryValue,
            ),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        if (reset) {
          _documents
            ..clear()
            ..addAll(response.items);
        } else {
          _documents.addAll(response.items);
        }
        _nextCursor = response.nextCursor;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _setEntityFilter(_DocumentsEntityFilter value) {
    if (value == _selectedEntityFilter) {
      return;
    }
    setState(() => _selectedEntityFilter = value);
    _loadDocuments(reset: true);
  }

  void _setKindFilter(_DocumentsKindFilter value) {
    if (value == _selectedKindFilter) {
      return;
    }
    setState(() => _selectedKindFilter = value);
    _loadDocuments(reset: true);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      _loadDocuments(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(petAccessPolicyProvider(widget.petId));
    final viewerItems = _documents
        .map(
          (document) => AttachmentViewerItem.fromAttachment(
            fileId: document.fileId,
            fileType: document.fileType,
            fileName: document.fileName,
            previewUrl: document.previewUrl,
            downloadUrl: document.downloadUrl,
          ),
        )
        .toList(growable: false);

    return PawlyScreenScaffold(
      title: 'Документы',
      body: accessAsync.when(
        data: (access) {
          if (!access.documentsRead) {
            return const _PetDocumentsNoAccessView();
          }
          if (!_didRequestInitialLoad) {
            _didRequestInitialLoad = true;
            Future<void>.microtask(() => _loadDocuments(reset: true));
          }
          return switch ((_isInitialLoading, _error, _documents.isEmpty)) {
            (true, _, _) => const Center(child: CircularProgressIndicator()),
            (_, final error?, true) => _PetDocumentsErrorView(
                message: error.toString(),
                onRetry: () => _loadDocuments(reset: true),
              ),
            (_, _, true) => _PetDocumentsEmptyView(
                searchController: _searchController,
                selectedEntityFilter: _selectedEntityFilter,
                selectedKindFilter: _selectedKindFilter,
                onSearchChanged: _onSearchChanged,
                onEntityFilterChanged: _setEntityFilter,
                onKindFilterChanged: _setKindFilter,
              ),
            _ => RefreshIndicator(
                onRefresh: () => _loadDocuments(reset: true),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    PawlySpacing.md,
                    PawlySpacing.sm,
                    PawlySpacing.md,
                    PawlySpacing.xl,
                  ),
                  children: <Widget>[
                    _DocumentsFilterSection(
                      searchController: _searchController,
                      selectedEntityFilter: _selectedEntityFilter,
                      selectedKindFilter: _selectedKindFilter,
                      onSearchChanged: _onSearchChanged,
                      onEntityFilterChanged: _setEntityFilter,
                      onKindFilterChanged: _setKindFilter,
                    ),
                    const SizedBox(height: PawlySpacing.md),
                    if (!access.healthWrite && !access.logWrite) ...<Widget>[
                      const _DocumentsReadOnlyNotice(),
                      const SizedBox(height: PawlySpacing.md),
                    ],
                    ...List<Widget>.generate(_documents.length, (index) {
                      final document = _documents[index];
                      final viewerItem = viewerItems[index];
                      final canRename = document.id != null &&
                          _canRenameDocument(access, document);

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _documents.length - 1 &&
                                  _nextCursor == null
                              ? 0
                              : PawlySpacing.sm,
                        ),
                        child: _DocumentCard(
                          viewerItem: viewerItem,
                          entityLabel: _entityLabel(document.entityType),
                          meta: _documentMeta(document),
                          openEntityLabel: _openEntityLabel(
                            document.entityType,
                          ),
                          isRenaming: document.id != null &&
                              _renamingDocumentIds.contains(document.id),
                          onOpen: () => openAttachmentUrl(
                            context,
                            fileId: document.fileId,
                            fileType: document.fileType,
                            fileName: viewerItem.title,
                            previewUrl: document.previewUrl,
                            downloadUrl: document.downloadUrl,
                          ),
                          onRename: canRename
                              ? () => _renameDocument(document)
                              : null,
                          onOpenEntity: () =>
                              _openRelatedEntity(context, document),
                        ),
                      );
                    }),
                    if (_nextCursor != null) ...<Widget>[
                      const SizedBox(height: PawlySpacing.sm),
                      _LoadMoreCard(
                        isLoading: _isLoadingMore,
                        onPressed: _isLoadingMore
                            ? null
                            : () => _loadDocuments(reset: false),
                      ),
                    ],
                  ],
                ),
              ),
          };
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _PetDocumentsErrorView(
          message: 'Не удалось проверить права доступа.',
          onRetry: () => ref.invalidate(petAccessPolicyProvider(widget.petId)),
        ),
      ),
    );
  }

  String _documentMeta(PetDocument document) {
    final parts = <String>[
      _fileTypeLabel(document.fileType),
      if (document.addedAt != null) _formatDate(document.addedAt!),
    ];
    return parts.join(' • ');
  }

  String _entityLabel(String entityType) {
    return switch (entityType.trim().toLowerCase()) {
      'log' => 'Запись',
      'vet_visit' => 'Визит',
      'vaccination' => 'Вакцинация',
      'procedure' => 'Процедура',
      'medical_record' => 'Медкарта',
      _ => 'Документ',
    };
  }

  String _openEntityLabel(String entityType) {
    return switch (entityType.trim().toLowerCase()) {
      'log' => 'К записи',
      'vet_visit' => 'К визиту',
      'vaccination' => 'К вакцинации',
      'procedure' => 'К процедуре',
      'medical_record' => 'К медкарте',
      _ => 'К сущности',
    };
  }

  String _fileTypeLabel(String fileType) {
    return switch (detectAttachmentKind(fileType: fileType)) {
      AttachmentKind.image => 'Изображение',
      AttachmentKind.pdf => 'PDF',
      AttachmentKind.other => 'Файл',
    };
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }

  void _openRelatedEntity(BuildContext context, PetDocument document) {
    final normalizedType = document.entityType.trim().toLowerCase();

    switch (normalizedType) {
      case 'log':
        context.pushNamed(
          'petLogDetails',
          pathParameters: <String, String>{
            'petId': widget.petId,
            'logId': document.entityId,
          },
        );
        return;
      case 'vet_visit':
        context.pushNamed(
          'petVetVisitDetails',
          pathParameters: <String, String>{
            'petId': widget.petId,
            'visitId': document.entityId,
          },
        );
        return;
      case 'vaccination':
        context.pushNamed(
          'petVaccinationDetails',
          pathParameters: <String, String>{
            'petId': widget.petId,
            'vaccinationId': document.entityId,
          },
        );
        return;
      case 'procedure':
        context.pushNamed(
          'petProcedureDetails',
          pathParameters: <String, String>{
            'petId': widget.petId,
            'procedureId': document.entityId,
          },
        );
        return;
      case 'medical_record':
        context.pushNamed(
          'petMedicalRecordDetails',
          pathParameters: <String, String>{
            'petId': widget.petId,
            'recordId': document.entityId,
          },
        );
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Для этого документа переход к сущности недоступен.'),
      ),
    );
  }

  String? _nonEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _renameDocument(PetDocument document) async {
    final documentId = document.id;
    if (documentId == null || _renamingDocumentIds.contains(documentId)) {
      return;
    }

    final currentName = document.fileName?.trim().isNotEmpty == true
        ? document.fileName!.trim()
        : 'Файл';
    final newName = await showAttachmentRenameDialog(
      context,
      initialName: currentName,
    );
    if (newName == null || newName == currentName || !mounted) {
      return;
    }

    setState(() => _renamingDocumentIds.add(documentId));
    try {
      final updated = await ref.read(healthRepositoryProvider).updateDocument(
            widget.petId,
            documentId,
            fileName: newName,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        final index = _documents.indexWhere((item) => item.id == documentId);
        if (index >= 0) {
          _documents[index] = updated;
        }
      });
      ref.invalidate(petDocumentsSummaryProvider(widget.petId));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось переименовать документ: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _renamingDocumentIds.remove(documentId));
      }
    }
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.viewerItem,
    required this.entityLabel,
    required this.meta,
    required this.openEntityLabel,
    required this.isRenaming,
    required this.onOpen,
    required this.onRename,
    required this.onOpenEntity,
  });

  final AttachmentViewerItem viewerItem;
  final String entityLabel;
  final String meta;
  final String openEntityLabel;
  final bool isRenaming;
  final VoidCallback onOpen;
  final VoidCallback? onRename;
  final VoidCallback onOpenEntity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(PawlyRadius.xl),
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(PawlyRadius.xl),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(PawlySpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DocumentPreview(item: viewerItem, kind: viewerItem.kind),
              const SizedBox(width: PawlySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      viewerItem.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xxs),
                    Text(
                      '$entityLabel · $meta',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    InkWell(
                      onTap: onOpenEntity,
                      borderRadius: BorderRadius.circular(PawlyRadius.pill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: PawlySpacing.xxs,
                        ),
                        child: Text(
                          openEntityLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    onPressed: isRenaming ? null : onRename,
                    icon: isRenaming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit_rounded),
                    tooltip: 'Переименовать',
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.item, required this.kind});

  final AttachmentViewerItem item;
  final AttachmentKind kind;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (kind == AttachmentKind.image && item.url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(PawlyRadius.md),
        child: SizedBox(
          width: 56,
          height: 56,
          child: PawlyCachedImage(
            imageUrl: item.url!,
            cacheKey: item.cacheKeyFor('document-preview'),
            fit: BoxFit.cover,
            errorWidget: (_) => _fallbackIcon(colorScheme),
          ),
        ),
      );
    }

    return _fallbackIcon(colorScheme);
  }

  Widget _fallbackIcon(ColorScheme colorScheme) {
    final icon = switch (kind) {
      AttachmentKind.image => Icons.photo_library_rounded,
      AttachmentKind.pdf => Icons.picture_as_pdf_rounded,
      AttachmentKind.other => Icons.description_rounded,
    };

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.64),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: colorScheme.onSurfaceVariant),
    );
  }
}

class _DocumentsFilterSection extends StatelessWidget {
  const _DocumentsFilterSection({
    required this.searchController,
    required this.selectedEntityFilter,
    required this.selectedKindFilter,
    required this.onSearchChanged,
    required this.onEntityFilterChanged,
    required this.onKindFilterChanged,
  });

  final TextEditingController searchController;
  final _DocumentsEntityFilter selectedEntityFilter;
  final _DocumentsKindFilter selectedKindFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_DocumentsEntityFilter> onEntityFilterChanged;
  final ValueChanged<_DocumentsKindFilter> onKindFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PawlyTextField(
          controller: searchController,
          label: 'Поиск',
          hintText: 'Название файла',
          textInputAction: TextInputAction.search,
          prefixIcon: const Icon(Icons.search_rounded),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: PawlySpacing.md),
        Text(
          'Тип файла',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        _HorizontalFilterList<_DocumentsKindFilter>(
          values: _DocumentsKindFilter.values,
          selectedValue: selectedKindFilter,
          labelBuilder: (filter) => filter.label,
          onChanged: onKindFilterChanged,
        ),
        const SizedBox(height: PawlySpacing.sm),
        Text(
          'Источник',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        _HorizontalFilterList<_DocumentsEntityFilter>(
          values: _DocumentsEntityFilter.values,
          selectedValue: selectedEntityFilter,
          labelBuilder: (filter) => filter.label,
          onChanged: onEntityFilterChanged,
        ),
      ],
    );
  }
}

class _HorizontalFilterList<T> extends StatelessWidget {
  const _HorizontalFilterList({
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List<Widget>.generate(values.length, (index) {
          final value = values[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == values.length - 1 ? 0 : PawlySpacing.xs,
            ),
            child: _DocumentFilterPill(
              label: labelBuilder(value),
              isSelected: value == selectedValue,
              onTap: () => onChanged(value),
            ),
          );
        }),
      ),
    );
  }
}

class _DocumentFilterPill extends StatelessWidget {
  const _DocumentFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.pill),
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(PawlyRadius.pill),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.md,
          vertical: PawlySpacing.xs,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

enum _DocumentsKindFilter {
  all('Все', null),
  images('Фото', 'image'),
  pdf('PDF', 'pdf');

  const _DocumentsKindFilter(this.label, this.queryValue);

  final String label;
  final String? queryValue;
}

enum _DocumentsEntityFilter {
  all('Все сущности', null),
  logs('Записи', 'log'),
  visits('Визиты', 'vet_visit'),
  vaccinations('Вакцинации', 'vaccination'),
  procedures('Процедуры', 'procedure'),
  medicalRecords('Медкарта', 'medical_record');

  const _DocumentsEntityFilter(this.label, this.queryValue);

  final String label;
  final String? queryValue;
}

class _LoadMoreCard extends StatelessWidget {
  const _LoadMoreCard({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.sm),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : TextButton(
                  onPressed: onPressed,
                  child: const Text('Показать ещё'),
                ),
        ),
      ),
    );
  }
}

class _PetDocumentsEmptyView extends StatelessWidget {
  const _PetDocumentsEmptyView({
    required this.searchController,
    required this.selectedEntityFilter,
    required this.selectedKindFilter,
    required this.onSearchChanged,
    required this.onEntityFilterChanged,
    required this.onKindFilterChanged,
  });

  final TextEditingController searchController;
  final _DocumentsEntityFilter selectedEntityFilter;
  final _DocumentsKindFilter selectedKindFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_DocumentsEntityFilter> onEntityFilterChanged;
  final ValueChanged<_DocumentsKindFilter> onKindFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        _DocumentsFilterSection(
          searchController: searchController,
          selectedEntityFilter: selectedEntityFilter,
          selectedKindFilter: selectedKindFilter,
          onSearchChanged: onSearchChanged,
          onEntityFilterChanged: onEntityFilterChanged,
          onKindFilterChanged: onKindFilterChanged,
        ),
        const SizedBox(height: PawlySpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.62,
                    ),
                    borderRadius: BorderRadius.circular(PawlyRadius.xl),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.64,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.folder_open_rounded,
                    size: 34,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                Text(
                  'Документы не найдены',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Смените фильтр или добавьте файлы в записи и медицинские сущности.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PetDocumentsNoAccessView extends StatelessWidget {
  const _PetDocumentsNoAccessView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Нет доступа',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'У вас нет права просмотра документов этого питомца.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentsReadOnlyNotice extends StatelessWidget {
  const _DocumentsReadOnlyNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: PawlySpacing.sm),
            Expanded(
              child: Text(
                'Редактирование недоступно',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetDocumentsErrorView extends StatelessWidget {
  const _PetDocumentsErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Не удалось загрузить документы',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyButton(
                  label: 'Повторить',
                  onPressed: onRetry,
                  variant: PawlyButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _canRenameDocument(PetAccessPolicy access, PetDocument document) {
  if (document.entityType.trim().toUpperCase() == 'LOG') {
    return access.logWrite;
  }
  return access.healthWrite;
}
