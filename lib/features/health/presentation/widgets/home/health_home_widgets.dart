import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../states/home/health_home_state.dart';

class HealthHomeView extends StatelessWidget {
  const HealthHomeView({
    required this.state,
    required this.onRetry,
    required this.onSectionTap,
    super.key,
  });

  final PetHealthHomeState state;
  final VoidCallback onRetry;
  final ValueChanged<PetHealthSectionType> onSectionTap;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return HealthHomeNoAccessView(onRetry: onRetry);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        ...state.sections.map(
          (section) => HealthEntityCard(
            section: section,
            onTap: () => onSectionTap(section.type),
          ),
        ),
      ],
    );
  }
}

class HealthEntityCard extends StatelessWidget {
  const HealthEntityCard({
    required this.section,
    required this.onTap,
    super.key,
  });

  final PetHealthHomeSectionState section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _accentColor(section.type, colorScheme);

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(PawlyRadius.lg),
                    color: accent.withValues(alpha: 0.12),
                  ),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(_icon(section.type), color: accent, size: 24),
                  ),
                ),
                const SizedBox(width: PawlySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _title(section.type),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: PawlySpacing.sm),
                          HealthCountPill(label: section.countLabel),
                        ],
                      ),
                      const SizedBox(height: PawlySpacing.xxs),
                      Text(
                        _description(section.type),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(PetHealthSectionType type) {
    return switch (type) {
      PetHealthSectionType.vetVisits => 'Визиты',
      PetHealthSectionType.vaccinations => 'Вакцинации',
      PetHealthSectionType.procedures => 'Процедуры',
      PetHealthSectionType.medicalRecords => 'Медкарта',
    };
  }

  String _description(PetHealthSectionType type) {
    return switch (type) {
      PetHealthSectionType.vetVisits =>
        'Плановые и завершенные визиты к ветеринару',
      PetHealthSectionType.vaccinations => 'План вакцинации и история прививок',
      PetHealthSectionType.procedures => 'Профилактика',
      PetHealthSectionType.medicalRecords =>
        'Диагнозы, аллергии и клинические записи',
    };
  }

  IconData _icon(PetHealthSectionType type) {
    return switch (type) {
      PetHealthSectionType.vetVisits => Icons.add_box_rounded,
      PetHealthSectionType.vaccinations => Icons.vaccines_rounded,
      PetHealthSectionType.procedures => Icons.healing_rounded,
      PetHealthSectionType.medicalRecords => Icons.description_rounded,
    };
  }

  Color _accentColor(PetHealthSectionType type, ColorScheme colorScheme) {
    return switch (type) {
      PetHealthSectionType.vetVisits => const Color(0xFF155E63),
      PetHealthSectionType.vaccinations => const Color(0xFF176B55),
      PetHealthSectionType.procedures => const Color(0xFF2B5DA8),
      PetHealthSectionType.medicalRecords => colorScheme.primary,
    };
  }
}

class HealthCountPill extends StatelessWidget {
  const HealthCountPill({
    required this.label,
    super.key,
  });

  final String label;

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
          vertical: PawlySpacing.xxxs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class HealthHomeNoAccessView extends StatelessWidget {
  const HealthHomeNoAccessView({
    required this.onRetry,
    super.key,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _HealthHomeMessageView(
      title: 'Нет доступа к разделу здоровья',
      message: 'У текущей роли нет права health_read для этого питомца.',
      onRetry: onRetry,
    );
  }
}

class HealthHomeErrorView extends StatelessWidget {
  const HealthHomeErrorView({
    required this.onRetry,
    super.key,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _HealthHomeMessageView(
      title: 'Не удалось загрузить раздел здоровья',
      message: 'Проверьте сеть или повторите запрос ещё раз.',
      onRetry: onRetry,
    );
  }
}

class _HealthHomeMessageView extends StatelessWidget {
  const _HealthHomeMessageView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
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
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: PawlySpacing.xs),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
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
