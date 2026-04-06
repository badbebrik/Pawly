import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../core/services/attachment_launcher.dart';
import '../../../../design_system/design_system.dart';
import '../../data/health_repository_models.dart';
import '../models/attachment_kind.dart';
import '../models/attachment_viewer_item.dart';
import '../providers/health_controllers.dart';

class PetDocumentsPage extends ConsumerStatefulWidget {
  const PetDocumentsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetDocumentsPage> createState() => _PetDocumentsPageState();
}

class _PetDocumentsPageState extends ConsumerState<PetDocumentsPage> {
  static const _pageSize = 30;

  final List<PetDocument> _documents = <PetDocument>[];
  _DocumentsEntityFilter _selectedEntityFilter = _DocumentsEntityFilter.all;
  _DocumentsKindFilter _selectedKindFilter = _DocumentsKindFilter.all;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  Object? _error;
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => _loadDocuments(reset: true));
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
        _isInitialLoading = true;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewerItems = _documents
        .map(
          (document) => AttachmentViewerItem.fromAttachment(
            fileType: document.fileType,
            fileName: document.fileName,
            previewUrl: document.previewUrl,
            downloadUrl: document.downloadUrl,
          ),
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Документы')),
      body: switch ((_isInitialLoading, _error, _documents.isEmpty)) {
        (true, _, _) => const Center(child: CircularProgressIndicator()),
        (_, final error?, true) => _PetDocumentsErrorView(
            message: error.toString(),
            onRetry: () => _loadDocuments(reset: true),
          ),
        (_, _, true) => _PetDocumentsEmptyView(
            selectedEntityFilter: _selectedEntityFilter,
            selectedKindFilter: _selectedKindFilter,
            onEntityFilterChanged: _setEntityFilter,
            onKindFilterChanged: _setKindFilter,
          ),
        _ => RefreshIndicator(
            onRefresh: () => _loadDocuments(reset: true),
            child: ListView(
              padding: const EdgeInsets.all(PawlySpacing.lg),
              children: <Widget>[
                _DocumentsFilterSection(
                  selectedEntityFilter: _selectedEntityFilter,
                  selectedKindFilter: _selectedKindFilter,
                  onEntityFilterChanged: _setEntityFilter,
                  onKindFilterChanged: _setKindFilter,
                ),
                const SizedBox(height: PawlySpacing.md),
                ...List<Widget>.generate(_documents.length, (index) {
                  final document = _documents[index];
                  final viewerItem = viewerItems[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _documents.length - 1 && _nextCursor == null
                          ? 0
                          : PawlySpacing.sm,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(PawlyRadius.lg),
                        onTap: () => openAttachmentUrl(
                          context,
                          fileType: document.fileType,
                          fileName: viewerItem.title,
                          previewUrl: document.previewUrl,
                          downloadUrl: document.downloadUrl,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(PawlyRadius.lg),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: PawlySpacing.md,
                              vertical: PawlySpacing.xs,
                            ),
                            leading: _DocumentPreview(
                              item: viewerItem,
                              kind: viewerItem.kind,
                            ),
                            title: Text(
                              viewerItem.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: PawlySpacing.xxxs),
                                Text(_entityLabel(document.entityType)),
                                const SizedBox(height: PawlySpacing.xxxs),
                                Text(
                                  _documentMeta(document),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: PawlySpacing.xs),
                                TextButton.icon(
                                  onPressed: () => _openRelatedEntity(context, document),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    alignment: Alignment.centerLeft,
                                    foregroundColor: theme.colorScheme.primary,
                                  ),
                                  icon: const Icon(
                                    Icons.subdirectory_arrow_right_rounded,
                                    size: 18,
                                  ),
                                  label: Text(_openEntityLabel(document.entityType)),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
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
      },
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
      'log' => 'Лог',
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
      const SnackBar(content: Text('Для этого документа переход к сущности недоступен.')),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({
    required this.item,
    required this.kind,
  });

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
          child: Image.network(
            item.url!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackIcon(colorScheme),
          ),
        ),
      );
    }

    return _fallbackIcon(colorScheme);
  }

  Widget _fallbackIcon(ColorScheme colorScheme) {
    final (icon, accent) = switch (kind) {
      AttachmentKind.image => (Icons.photo_library_rounded, const Color(0xFF2B7A78)),
      AttachmentKind.pdf => (Icons.picture_as_pdf_rounded, const Color(0xFFC84B31)),
      AttachmentKind.other => (Icons.description_rounded, colorScheme.primary),
    };

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(PawlyRadius.md),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: accent),
    );
  }
}

class _DocumentsFilterSection extends StatelessWidget {
  const _DocumentsFilterSection({
    required this.selectedEntityFilter,
    required this.selectedKindFilter,
    required this.onEntityFilterChanged,
    required this.onKindFilterChanged,
  });

  final _DocumentsEntityFilter selectedEntityFilter;
  final _DocumentsKindFilter selectedKindFilter;
  final ValueChanged<_DocumentsEntityFilter> onEntityFilterChanged;
  final ValueChanged<_DocumentsKindFilter> onKindFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Фильтры',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: PawlySpacing.sm),
        Wrap(
          spacing: PawlySpacing.xs,
          runSpacing: PawlySpacing.xs,
          children: _DocumentsKindFilter.values
              .map(
                (filter) => ChoiceChip(
                  label: Text(filter.label),
                  selected: filter == selectedKindFilter,
                  onSelected: (_) => onKindFilterChanged(filter),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: PawlySpacing.sm),
        Wrap(
          spacing: PawlySpacing.xs,
          runSpacing: PawlySpacing.xs,
          children: _DocumentsEntityFilter.values
              .map(
                (filter) => ChoiceChip(
                  label: Text(filter.label),
                  selected: filter == selectedEntityFilter,
                  onSelected: (_) => onEntityFilterChanged(filter),
                ),
              )
              .toList(growable: false),
        ),
      ],
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
  logs('Логи', 'log'),
  visits('Визиты', 'vet_visit'),
  vaccinations('Вакцинации', 'vaccination'),
  procedures('Процедуры', 'procedure'),
  medicalRecords('Медкарта', 'medical_record');

  const _DocumentsEntityFilter(this.label, this.queryValue);

  final String label;
  final String? queryValue;
}

class _LoadMoreCard extends StatelessWidget {
  const _LoadMoreCard({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      child: Center(
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(PawlySpacing.xs),
                child: CircularProgressIndicator(),
              )
            : TextButton(
                onPressed: onPressed,
                child: const Text('Показать ещё'),
              ),
      ),
    );
  }
}

class _PetDocumentsEmptyView extends StatelessWidget {
  const _PetDocumentsEmptyView({
    required this.selectedEntityFilter,
    required this.selectedKindFilter,
    required this.onEntityFilterChanged,
    required this.onKindFilterChanged,
  });

  final _DocumentsEntityFilter selectedEntityFilter;
  final _DocumentsKindFilter selectedKindFilter;
  final ValueChanged<_DocumentsEntityFilter> onEntityFilterChanged;
  final ValueChanged<_DocumentsKindFilter> onKindFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        _DocumentsFilterSection(
          selectedEntityFilter: selectedEntityFilter,
          selectedKindFilter: selectedKindFilter,
          onEntityFilterChanged: onEntityFilterChanged,
          onKindFilterChanged: onKindFilterChanged,
        ),
        const SizedBox(height: PawlySpacing.lg),
        PawlyCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(PawlyRadius.xl),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 36,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: PawlySpacing.md),
              Text(
                'Документы не найдены',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PawlySpacing.xs),
              Text(
                'Смени фильтр или добавь файлы в записи и медицинские сущности.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PetDocumentsErrorView extends StatelessWidget {
  const _PetDocumentsErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Не удалось загрузить документы',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: PawlySpacing.xs),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }
}
