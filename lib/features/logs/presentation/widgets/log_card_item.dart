import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/log_models.dart';
import '../../shared/formatters/log_display_formatters.dart';
import '../../shared/formatters/log_type_sticker_formatter.dart';

class LogCardItem extends StatelessWidget {
  const LogCardItem({
    required this.log,
    required this.logTypeCode,
    required this.onTap,
    super.key,
  });

  final LogListItem log;
  final String? logTypeCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sticker = logTypeStickerForCode(code: logTypeCode);
    final singleMetric = log.metricValuesPreview.length == 1
        ? log.metricValuesPreview.single
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PawlyRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PawlyRadius.xl),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
            ),
            padding: const EdgeInsets.all(PawlySpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: Text(
                      sticker.emoji,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ),
                const SizedBox(width: PawlySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        log.logTypeName ?? 'Запись без типа',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: PawlySpacing.xxs),
                      Text(
                        formatLogDateTime(
                          log.occurredAt,
                          emptyLabel: 'Дата не указана',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (singleMetric != null) ...<Widget>[
                        const SizedBox(height: PawlySpacing.sm),
                        Text(
                          '${singleMetric.metricName}: ${formatLogMetricValue(singleMetric)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      if (log.descriptionPreview.isNotEmpty) ...<Widget>[
                        const SizedBox(height: PawlySpacing.sm),
                        Text(
                          log.descriptionPreview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if (logListRelatedEntityLabel(log)
                          case final relatedLabel?) ...<Widget>[
                        const SizedBox(height: PawlySpacing.xs),
                        Text(
                          relatedLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (log.hasAttachments) ...<Widget>[
                        const SizedBox(height: PawlySpacing.sm),
                        Wrap(
                          spacing: PawlySpacing.xs,
                          runSpacing: PawlySpacing.xs,
                          children: <Widget>[
                            _LogMetaToken(
                              label: 'Вложений: ${log.attachmentsCount}',
                              icon: Icons.attach_file_rounded,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogMetaToken extends StatelessWidget {
  const _LogMetaToken({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.sm,
          vertical: PawlySpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: PawlySpacing.xxs),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
