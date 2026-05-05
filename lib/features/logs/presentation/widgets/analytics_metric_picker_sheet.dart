import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/analytics_models.dart';
import '../../shared/formatters/analytics_formatters.dart';
import '../../shared/utils/log_catalog_filters.dart';

class AnalyticsMetricPickerSheet extends StatefulWidget {
  const AnalyticsMetricPickerSheet({
    required this.metrics,
    required this.selectedMetricId,
    super.key,
  });

  final List<AnalyticsMetricItem> metrics;
  final String selectedMetricId;

  @override
  State<AnalyticsMetricPickerSheet> createState() =>
      _AnalyticsMetricPickerSheetState();
}

class _AnalyticsMetricPickerSheetState
    extends State<AnalyticsMetricPickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMetrics = filterAnalyticsMetricsByName(
      metrics: widget.metrics,
      query: _query,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: PawlySpacing.lg,
          right: PawlySpacing.lg,
          top: PawlySpacing.md,
          bottom: PawlySpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Выберите показатель',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: PawlySpacing.md),
            PawlyTextField(
              controller: _searchController,
              hintText: 'Поиск по показателям',
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            const SizedBox(height: PawlySpacing.md),
            Flexible(
              child: filteredMetrics.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(PawlySpacing.lg),
                        child: Text('Показатели не найдены.'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredMetrics.length,
                      itemBuilder: (context, index) {
                        final metric = filteredMetrics[index];
                        final isSelected =
                            metric.metricId == widget.selectedMetricId;
                        return _AnalyticsMetricOption(
                          title: metric.metricName,
                          subtitle: analyticsMetricSubtitle(metric),
                          isSelected: isSelected,
                          onTap: () =>
                              Navigator.of(context).pop(metric.metricId),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsMetricOption extends StatelessWidget {
  const _AnalyticsMetricOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.10)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PawlyRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(PawlySpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PawlyRadius.lg),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.52)
                    : colorScheme.outlineVariant.withValues(alpha: 0.64),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: PawlySpacing.xxs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
