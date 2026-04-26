import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class PetEditBottomActions extends StatelessWidget {
  const PetEditBottomActions({
    required this.isSubmitting,
    required this.onSubmit,
    this.onPrevious,
    this.onNext,
    super.key,
  });

  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final showNavigation = onPrevious != null || onNext != null;

    return Column(
      children: <Widget>[
        if (showNavigation) ...<Widget>[
          Row(
            children: <Widget>[
              if (onPrevious != null)
                Expanded(
                  child: PawlyButton(
                    label: 'Назад',
                    onPressed: onPrevious,
                    variant: PawlyButtonVariant.secondary,
                  ),
                ),
              if (onPrevious != null && onNext != null)
                const SizedBox(width: PawlySpacing.sm),
              if (onNext != null)
                Expanded(
                  child: PawlyButton(
                    label: 'Далее',
                    onPressed: onNext,
                    variant: PawlyButtonVariant.secondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: PawlySpacing.sm),
        ],
        PawlyButton(
          label: isSubmitting ? 'Сохраняем...' : 'Сохранить',
          onPressed: isSubmitting ? null : onSubmit,
        ),
      ],
    );
  }
}

class PetEditNoAccessView extends StatelessWidget {
  const PetEditNoAccessView({super.key});

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
                  'У вас нет права редактировать этого питомца.',
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
