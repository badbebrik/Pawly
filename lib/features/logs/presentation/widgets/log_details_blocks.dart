import 'package:flutter/material.dart';

import '../../../../core/services/attachment_launcher.dart';
import '../../../../design_system/design_system.dart';
import '../../models/log_models.dart';
import '../../shared/formatters/log_display_formatters.dart';
import '../../../shared/attachments/models/attachment_kind.dart';
import '../../../shared/attachments/models/attachment_viewer_item.dart';

class LogDetailsContentView extends StatelessWidget {
  const LogDetailsContentView({
    required this.log,
    required this.onRefresh,
    super.key,
  });

  final LogDetails log;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        children: <Widget>[
          LogDetailsHeaderCard(log: log),
          if (log.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            LogDetailsDescriptionCard(description: log.description),
          ],
          if (log.metricValues.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            LogDetailsMetricsCard(metrics: log.metricValues),
          ],
          if (log.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            LogDetailsAttachmentsCard(attachments: log.attachments),
          ],
          const SizedBox(height: PawlySpacing.md),
          LogDetailsSystemInfoCard(log: log),
        ],
      ),
    );
  }
}

class LogDetailsErrorView extends StatelessWidget {
  const LogDetailsErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить запись.'),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class LogDetailsHeaderCard extends StatelessWidget {
  const LogDetailsHeaderCard({required this.log, super.key});

  final LogDetails log;

  @override
  Widget build(BuildContext context) {
    final canMutate = log.canEdit || log.canDelete;

    return PawlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      log.logTypeName ?? 'Запись без типа',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: PawlySpacing.xxs),
                    Text(
                      formatLogDateTime(log.occurredAt),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (log.sourceLabel != null && log.sourceLabel!.isNotEmpty) ...[
            const SizedBox(height: PawlySpacing.sm),
            Text(
              log.sourceLabel!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ] else if (logDetailsRelatedEntityLabel(log)
              case final relatedLabel?) ...[
            const SizedBox(height: PawlySpacing.sm),
            Text(
              relatedLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          if (!canMutate) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            const PawlyBadge(
              label: 'Редактирование недоступно',
              tone: PawlyBadgeTone.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class LogDetailsDescriptionCard extends StatelessWidget {
  const LogDetailsDescriptionCard({required this.description, super.key});

  final String description;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      title: Text(
        'Описание',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      child: Text(description),
    );
  }
}

class LogDetailsMetricsCard extends StatelessWidget {
  const LogDetailsMetricsCard({required this.metrics, super.key});

  final List<LogMetricItem> metrics;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      title: Text(
        'Показатели',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      child: Column(
        children: metrics
            .map(
              (metric) => Padding(
                padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(metric.metricName)),
                    Text(
                      formatLogMetricValue(metric),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class LogDetailsAttachmentsCard extends StatelessWidget {
  const LogDetailsAttachmentsCard({required this.attachments, super.key});

  final List<LogAttachmentItem> attachments;

  @override
  Widget build(BuildContext context) {
    final viewerItems = attachments
        .map(
          (attachment) => AttachmentViewerItem.fromAttachment(
            fileId: attachment.fileId,
            fileType: attachment.fileType,
            fileName: attachment.fileName,
            previewUrl: attachment.previewUrl,
            downloadUrl: attachment.downloadUrl,
          ),
        )
        .toList(growable: false);
    final imageItems = viewerItems
        .where(
          (item) => item.kind == AttachmentKind.image && item.url != null,
        )
        .toList(growable: false);

    return PawlyCard(
      title: Text(
        'Вложения',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      child: Column(
        children: List<Widget>.generate(attachments.length, (index) {
          final attachment = attachments[index];
          final viewerItem = viewerItems[index];
          final imageIndex = imageItems.indexWhere(
            (item) =>
                item.url == viewerItem.url && item.title == viewerItem.title,
          );

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              switch (viewerItem.kind) {
                AttachmentKind.image => Icons.photo_rounded,
                AttachmentKind.pdf => Icons.picture_as_pdf_rounded,
                AttachmentKind.other => Icons.description_rounded,
              },
            ),
            title: Text(viewerItem.title),
            subtitle: Text(formatLogAttachmentSubtitle(attachment)),
            onTap: () => openAttachmentUrl(
              context,
              fileId: attachment.fileId,
              fileType: attachment.fileType,
              fileName: viewerItem.title,
              previewUrl: attachment.previewUrl,
              downloadUrl: attachment.downloadUrl,
              imageGalleryItems: imageItems,
              initialImageIndex: imageIndex >= 0 ? imageIndex : null,
            ),
          );
        }),
      ),
    );
  }
}

class LogDetailsSystemInfoCard extends StatelessWidget {
  const LogDetailsSystemInfoCard({required this.log, super.key});

  final LogDetails log;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      title: Text(
        'Служебная информация',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _MetaRow(
            label: 'Создано',
            value: formatLogDateTime(log.createdAt),
          ),
          _MetaRow(
            label: 'Обновлено',
            value: formatLogDateTime(log.updatedAt),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
