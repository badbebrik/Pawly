import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class AnalyticsCompactToolbar extends StatelessWidget {
  const AnalyticsCompactToolbar({
    required this.metricLabel,
    required this.onPickMetric,
    required this.onOpenFilters,
    required this.hasActiveFilters,
    required this.activeFiltersSummary,
    required this.isFiltersLoading,
    this.onExport,
    super.key,
  });

  final String metricLabel;
  final VoidCallback? onPickMetric;
  final VoidCallback onOpenFilters;
  final bool hasActiveFilters;
  final String? activeFiltersSummary;
  final bool isFiltersLoading;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _AnalyticsToolbarButton(
                onTap: onPickMetric,
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(PawlyRadius.md),
                      ),
                      child: Icon(
                        Icons.show_chart_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: PawlySpacing.sm),
                    Expanded(
                      child: Text(
                        metricLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
            const SizedBox(width: PawlySpacing.sm),
            _AnalyticsFilterButton(
              onTap: onOpenFilters,
              isLoading: isFiltersLoading,
              hasActiveFilters: hasActiveFilters,
            ),
            if (onExport != null) ...<Widget>[
              const SizedBox(width: PawlySpacing.sm),
              _AnalyticsExportButton(onTap: onExport!),
            ],
          ],
        ),
        if (activeFiltersSummary != null) ...<Widget>[
          const SizedBox(height: PawlySpacing.xs),
          Text(
            activeFiltersSummary!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _AnalyticsExportButton extends StatelessWidget {
  const _AnalyticsExportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(PawlyRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
          ),
          child: Icon(
            Icons.file_download_outlined,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _AnalyticsToolbarButton extends StatelessWidget {
  const _AnalyticsToolbarButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(PawlyRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AnalyticsFilterButton extends StatelessWidget {
  const _AnalyticsFilterButton({
    required this.onTap,
    required this.isLoading,
    required this.hasActiveFilters,
  });

  final VoidCallback onTap;
  final bool isLoading;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(PawlyRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.tune_rounded, color: colorScheme.onSurface),
              if (hasActiveFilters)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
