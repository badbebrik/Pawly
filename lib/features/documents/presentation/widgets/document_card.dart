import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../shared/attachments/models/attachment_kind.dart';
import '../../../shared/attachments/models/attachment_viewer_item.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    required this.viewerItem,
    required this.entityLabel,
    required this.meta,
    required this.openEntityLabel,
    required this.isRenaming,
    required this.onOpen,
    required this.onRename,
    required this.onOpenEntity,
    super.key,
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
            targetLogicalSize: 56,
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
