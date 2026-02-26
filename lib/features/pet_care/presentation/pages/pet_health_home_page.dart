import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../providers/pet_health_home_controllers.dart';

class PetHealthHomePage extends ConsumerWidget {
  const PetHealthHomePage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(petHealthHomeProvider(petId));

    return Scaffold(
      appBar: AppBar(title: const Text('Здоровье')),
      body: stateAsync.when(
        data: (state) => _PetHealthHomeView(
          petId: petId,
          state: state,
          onRetry: () => ref.invalidate(petHealthHomeProvider(petId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PetHealthHomeErrorView(
          onRetry: () => ref.invalidate(petHealthHomeProvider(petId)),
        ),
      ),
    );
  }
}

class _PetHealthHomeView extends StatelessWidget {
  const _PetHealthHomeView({
    required this.petId,
    required this.state,
    required this.onRetry,
  });

  final String petId;
  final PetHealthHomeState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!state.canRead) {
      return _PetHealthNoAccessView(onRetry: onRetry);
    }

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        Text(
          state.petName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: PawlySpacing.xxs),
        Text(
          state.canWrite
              ? 'Раздел здоровья'
              : 'Раздел здоровья · только просмотр',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: PawlySpacing.lg),
        ...state.sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: PawlySpacing.md),
            child: _HealthEntityCard(
              section: section,
              onTap: () => _handleSectionTap(context, section.type),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSectionTap(BuildContext context, PetHealthSectionType type) {
    if (type == PetHealthSectionType.vetVisits) {
      context.pushNamed(
        'petVetVisits',
        pathParameters: <String, String>{'petId': petId},
      );
      return;
    }

    if (type == PetHealthSectionType.vaccinations) {
      context.pushNamed(
        'petVaccinations',
        pathParameters: <String, String>{'petId': petId},
      );
      return;
    }

    if (type == PetHealthSectionType.medicalRecords) {
      context.pushNamed(
        'petMedicalRecords',
        pathParameters: <String, String>{'petId': petId},
      );
      return;
    }

    final label = switch (type) {
      PetHealthSectionType.vetVisits => 'Визиты',
      PetHealthSectionType.vaccinations => 'Вакцинации',
      PetHealthSectionType.procedures => 'Процедуры',
      PetHealthSectionType.medicalRecords => 'Медкарта',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Раздел "$label" подключим следующим экраном.')),
    );
  }
}

class _HealthEntityCard extends StatelessWidget {
  const _HealthEntityCard({
    required this.section,
    required this.onTap,
  });

  final PetHealthHomeSectionState section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _accentColor(section.type, colorScheme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: PawlyElevation.soft(colorScheme.shadow),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.14),
                  ),
                  child: Icon(_icon(section.type), color: accent, size: 30),
                ),
                const SizedBox(width: PawlySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _title(section.type),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: PawlySpacing.xxs),
                      Text(
                        _description(section.type),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: PawlySpacing.sm),
                      Text(
                        section.countLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 30,
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
      PetHealthSectionType.procedures =>
        'Профилактика, уход и лечебные процедуры',
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

class _PetHealthNoAccessView extends StatelessWidget {
  const _PetHealthNoAccessView({required this.onRetry});

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
                'Нет доступа к разделу здоровья',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: PawlySpacing.xs),
              Text(
                'У текущей роли нет права health_read для этого питомца.',
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

class _PetHealthHomeErrorView extends StatelessWidget {
  const _PetHealthHomeErrorView({required this.onRetry});

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
                'Не удалось загрузить раздел здоровья',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: PawlySpacing.xs),
              Text(
                'Проверь сеть или повтори запрос ещё раз.',
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
