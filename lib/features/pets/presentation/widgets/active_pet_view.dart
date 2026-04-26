import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/active_pet_controller.dart';
import '../../controllers/active_pet_details_controller.dart';
import '../../models/pet_access_policy.dart';
import '../../models/pet_list_entry.dart';
import '../../shared/formatters/pet_age_formatter.dart';
import '../../shared/widgets/pets_error_view.dart';
import 'active_pet_actions.dart';
import 'active_pet_feature_card.dart';
import 'active_pet_hero_card.dart';

class ActivePetView extends ConsumerWidget {
  const ActivePetView({required this.entry, super.key});

  final PetListEntry? entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petDetailsAsync = ref.watch(activePetDetailsControllerProvider);

    return petDetailsAsync.when(
      data: (details) {
        if (details == null) {
          return PetsErrorView(
            message: 'Активный питомец не найден.',
            onRetry: () =>
                ref.read(activePetControllerProvider.notifier).clear(),
          );
        }

        final pet = details.pet;
        final access = entry?.accessPolicy ??
            const PetAccessPolicy(permissions: <String, bool>{});
        final ageLabel = activePetAgeLabel(pet.birthDate);

        return ListView(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          children: <Widget>[
            ActivePetHeroCard(
              pet: pet,
              speciesName: details.speciesName,
              ageLabel: ageLabel,
              isUploadingPhoto: details.isUploadingPhoto,
              onPhotoTap: details.isUploadingPhoto || !access.petWrite
                  ? null
                  : () => showPetPhotoActionsSheet(context, ref, pet),
              onEdit: access.petWrite
                  ? () => context.pushNamed(
                        'petEdit',
                        pathParameters: {'petId': pet.id},
                      )
                  : null,
              onMore: () => showActivePetActionsSheet(
                context,
                ref,
                petName: pet.name,
                canArchive: access.petWrite,
              ),
            ),
            if (!access.petWrite) ...<Widget>[
              const SizedBox(height: PawlySpacing.md),
              const _ReadOnlyNotice(),
            ],
            const SizedBox(height: PawlySpacing.xl),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: PawlySpacing.md,
              crossAxisSpacing: PawlySpacing.md,
              childAspectRatio: 1.18,
              children: <Widget>[
                ActivePetFeatureCard(
                  title: 'Записи',
                  icon: Icons.edit_note_rounded,
                  tint: Theme.of(context).colorScheme.primary,
                  statusLabel: access.logRead ? null : 'Нет доступа',
                  onTap: access.logRead
                      ? () => context.pushNamed(
                            'petLogs',
                            pathParameters: <String, String>{'petId': pet.id},
                          )
                      : null,
                ),
                ActivePetFeatureCard(
                  title: 'Здоровье',
                  icon: Icons.health_and_safety_rounded,
                  tint: const Color(0xFF2C9C8C),
                  statusLabel: access.healthRead ? null : 'Нет доступа',
                  onTap: access.healthRead
                      ? () => context.pushNamed(
                            'petHealthHome',
                            pathParameters: <String, String>{'petId': pet.id},
                          )
                      : null,
                ),
                ActivePetFeatureCard(
                  title: 'Совместный доступ',
                  icon: Icons.group_rounded,
                  tint: const Color(0xFFB67A2D),
                  statusLabel: access.membersRead ? null : 'Нет доступа',
                  onTap: access.membersRead
                      ? () => context.pushNamed(
                            'aclAccess',
                            pathParameters: <String, String>{'petId': pet.id},
                          )
                      : null,
                ),
                ActivePetFeatureCard(
                  title: 'Динамика',
                  icon: Icons.bar_chart_rounded,
                  tint: const Color(0xFF5972D9),
                  statusLabel: access.logRead ? null : 'Нет доступа',
                  onTap: access.logRead
                      ? () => context.pushNamed(
                            'petAnalytics',
                            pathParameters: <String, String>{'petId': pet.id},
                          )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: PawlySpacing.md),
            ActivePetWideFeatureCard(
              title: 'Напоминания',
              icon: Icons.notifications_active_rounded,
              tint: const Color(0xFFEAA05D),
              onTap: access.remindersRead
                  ? () => context.pushNamed(
                        'petReminders',
                        pathParameters: <String, String>{'petId': pet.id},
                      )
                  : null,
            ),
            const SizedBox(height: PawlySpacing.md),
            ActivePetWideFeatureCard(
              title: 'Документы',
              icon: Icons.folder_copy_rounded,
              tint: const Color(0xFF6D5BD0),
              onTap: access.documentsRead
                  ? () => context.pushNamed(
                        'petDocuments',
                        pathParameters: <String, String>{'petId': pet.id},
                      )
                  : null,
            ),
            const SizedBox(height: PawlySpacing.xl),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => PetsErrorView(
        message: 'Не удалось загрузить карточку питомца.',
        onRetry: () =>
            ref.read(activePetDetailsControllerProvider.notifier).reload(),
      ),
    );
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.md,
        vertical: PawlySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: PawlySpacing.sm),
          Expanded(
            child: Text(
              'Редактирование недоступно',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
