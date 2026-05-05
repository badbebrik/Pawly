import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../models/log_constants.dart';
import '../../../models/log_models.dart';
import '../../../shared/formatters/log_form_formatters.dart';
import '../../../shared/formatters/log_metric_formatters.dart';

class LogMetricField extends StatelessWidget {
  const LogMetricField({
    required this.requirement,
    required this.enabled,
    required this.textController,
    required this.booleanValue,
    required this.onSetBooleanValue,
    super.key,
  });

  final LogTypeMetricRequirementItem requirement;
  final bool enabled;
  final TextEditingController textController;
  final bool? booleanValue;
  final ValueChanged<bool> onSetBooleanValue;

  @override
  Widget build(BuildContext context) {
    final label = logMetricRequirementLabel(requirement);
    if (requirement.inputKind == LogMetricInputKind.boolean) {
      return MetricFieldShell(
        title: label,
        subtitle: logMetricRequirementHint(requirement),
        child: Row(
          children: <Widget>[
            Expanded(
              child: LogBooleanChoice(
                label: 'Да',
                isSelected: booleanValue == true,
                enabled: enabled,
                onTap: () => onSetBooleanValue(true),
              ),
            ),
            const SizedBox(width: PawlySpacing.xs),
            Expanded(
              child: LogBooleanChoice(
                label: 'Нет',
                isSelected: booleanValue == false,
                enabled: enabled,
                onTap: () => onSetBooleanValue(false),
              ),
            ),
          ],
        ),
      );
    }

    return MetricFieldShell(
      title: label,
      subtitle: logMetricRequirementHint(requirement),
      child: TextFormField(
        controller: textController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: enabled,
        decoration: InputDecoration(
          hintText: logMetricPlaceholder(requirement),
          suffixIcon: (requirement.unitCode ?? '').trim().isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      formatDisplayUnitCode(requirement.unitCode),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class MetricFieldShell extends StatelessWidget {
  const MetricFieldShell({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(PawlyRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.56),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(PawlySpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: PawlySpacing.xxs),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: PawlySpacing.sm),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class LogBooleanChoice extends StatelessWidget {
  const LogBooleanChoice({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(PawlyRadius.pill),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.84),
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
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
