import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/log_models.dart';
import '../../shared/formatters/log_form_formatters.dart';

class TypeCreateErrorView extends StatelessWidget {
  const TypeCreateErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось подготовить создание типа.'),
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

class SelectedMetricEntry {
  const SelectedMetricEntry({
    required this.metric,
    required this.isRequired,
  });

  final LogMetricCatalogItem metric;
  final bool isRequired;
}

class SelectedMetricCard extends StatelessWidget {
  const SelectedMetricCard({
    required this.metric,
    required this.isRequired,
    required this.enabled,
    required this.onRequiredChanged,
    required this.onRemove,
    super.key,
  });

  final LogMetricCatalogItem metric;
  final bool isRequired;
  final bool enabled;
  final ValueChanged<bool> onRequiredChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      trailing: IconButton(
        onPressed: enabled ? onRemove : null,
        icon: const Icon(Icons.close_rounded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            metric.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            logMetricCatalogSubtitle(metric),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: PawlySpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: isRequired,
            onChanged: enabled ? onRequiredChanged : null,
            title: const Text('Обязательный показатель'),
          ),
        ],
      ),
    );
  }
}
