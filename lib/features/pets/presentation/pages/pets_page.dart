import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/models/pet_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../pet_care/presentation/providers/health_controllers.dart';
import '../../../chat/presentation/widgets/chat_app_bar_action.dart';
import '../../data/pets_repository.dart';
import '../providers/active_pet_controller.dart';
import '../providers/active_pet_details_controller.dart';
import '../providers/pets_controller.dart';

class PetsPage extends ConsumerWidget {
  const PetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePetAsync = ref.watch(activePetControllerProvider);
    final petsStateAsync = ref.watch(petsControllerProvider);
    final activePetId = activePetAsync.asData?.value;

    return PawlyScreenScaffold(
      title: 'Питомцы',
      actions: const <Widget>[
        ChatAppBarAction(),
      ],
      floatingActionButton: activePetId == null || activePetId.isEmpty
          ? _PetsActionsButton(
              onCreatePet: () => context.push(AppRoutes.petCreate),
              onJoinByCode: () => _showJoinByCodeDialog(context, ref),
            )
          : null,
      body: activePetAsync.when(
        data: (activePetId) {
          return petsStateAsync.when(
            data: (petsState) {
              if (activePetId == null || activePetId.isEmpty) {
                return _PetsListView(state: petsState);
              }

              return _ActivePetView(
                entry: _petListEntryById(petsState.items, activePetId),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _PetsErrorView(
              message: 'Не удалось загрузить питомцев.',
              onRetry: () => ref.read(petsControllerProvider.notifier).reload(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PetsErrorView(
          message: 'Не удалось восстановить активного питомца.',
          onRetry: () =>
              ref.read(activePetControllerProvider.notifier).reload(),
        ),
      ),
    );
  }
}

class _PetsListView extends ConsumerWidget {
  const _PetsListView({required this.state});

  final PetsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = state.filteredItems;
    final bucketCount = state.items.where((item) {
      return switch (state.statusBucket) {
        PetsStatusBucket.active => item.pet.status != 'ARCHIVED',
        PetsStatusBucket.archive => item.pet.status == 'ARCHIVED',
      };
    }).length;

    return ColoredBox(
      color: pawlyGroupedBackground(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.md,
          PawlySpacing.md,
          112,
        ),
        children: <Widget>[
          _PetsSearchField(
            initialValue: state.searchQuery,
            onChanged: (value) {
              ref.read(petsControllerProvider.notifier).setSearchQuery(value);
            },
          ),
          const SizedBox(height: PawlySpacing.md),
          _PetsSegmentedControl<PetsStatusBucket>(
            value: state.statusBucket,
            options: const <_PetsSegmentOption<PetsStatusBucket>>[
              _PetsSegmentOption<PetsStatusBucket>(
                value: PetsStatusBucket.active,
                label: 'Активные',
              ),
              _PetsSegmentOption<PetsStatusBucket>(
                value: PetsStatusBucket.archive,
                label: 'Архив',
              ),
            ],
            onChanged: (value) {
              ref.read(petsControllerProvider.notifier).setStatusBucket(value);
            },
          ),
          const SizedBox(height: PawlySpacing.sm),
          _PetsSegmentedControl<PetsOwnershipFilter>(
            value: state.ownershipFilter,
            compact: true,
            options: const <_PetsSegmentOption<PetsOwnershipFilter>>[
              _PetsSegmentOption<PetsOwnershipFilter>(
                value: PetsOwnershipFilter.all,
                label: 'Все',
              ),
              _PetsSegmentOption<PetsOwnershipFilter>(
                value: PetsOwnershipFilter.owned,
                label: 'Мои',
              ),
              _PetsSegmentOption<PetsOwnershipFilter>(
                value: PetsOwnershipFilter.shared,
                label: 'Не мои',
              ),
            ],
            onChanged: (value) {
              ref
                  .read(petsControllerProvider.notifier)
                  .setOwnershipFilter(value);
            },
          ),
          const SizedBox(height: PawlySpacing.md),
          _PetsSectionHeader(
            title: state.statusBucket == PetsStatusBucket.archive
                ? 'Архив'
                : 'Питомцы',
            count: bucketCount == items.length
                ? _petsCountLabel(items.length)
                : '${_petsCountLabel(items.length)} из $bucketCount',
          ),
          const SizedBox(height: PawlySpacing.xs),
          if (items.isEmpty)
            _PetsEmptyState(statusBucket: state.statusBucket)
          else
            _PetsCardsLayout(
              items: items,
              itemBuilder: (item) => _PetListCard(
                entry: item,
                onTap: state.statusBucket == PetsStatusBucket.archive
                    ? null
                    : () => ref
                        .read(activePetControllerProvider.notifier)
                        .selectPet(
                          item.id,
                        ),
                onRestore: state.statusBucket == PetsStatusBucket.archive
                    ? () => _restorePetFromArchive(context, ref, item.pet)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _PetsSectionHeader extends StatelessWidget {
  const _PetsSectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PawlySpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            count,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetsSearchField extends StatelessWidget {
  const _PetsSearchField({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
      ),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Поиск по имени',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.md,
          ),
        ),
      ),
    );
  }
}

class _PetsSegmentOption<T> {
  const _PetsSegmentOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class _PetsSegmentedControl<T> extends StatelessWidget {
  const _PetsSegmentedControl({
    required this.options,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final List<_PetsSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(PawlySpacing.xxs),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
      ),
      child: Row(
        children: options.map((option) {
          final selected = option.value == value;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(PawlySpacing.xxxs),
              child: _PetsSegmentButton(
                label: option.label,
                selected: selected,
                compact: compact,
                onTap: () => onChanged(option.value),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _PetsSegmentButton extends StatelessWidget {
  const _PetsSegmentButton({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground =
        selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.md),
        child: AnimatedContainer(
          duration: PawlyMotion.quick,
          height: compact ? 34 : 38,
          padding: const EdgeInsets.symmetric(horizontal: PawlySpacing.xs),
          decoration: BoxDecoration(
            color: selected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(PawlyRadius.md),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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

class _PetsEmptyState extends StatelessWidget {
  const _PetsEmptyState({required this.statusBucket});

  final PetsStatusBucket statusBucket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArchive = statusBucket == PetsStatusBucket.archive;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.lg,
        PawlySpacing.xl,
        PawlySpacing.lg,
        PawlySpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            isArchive ? Icons.archive_outlined : Icons.pets_rounded,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            size: 34,
          ),
          const SizedBox(height: PawlySpacing.sm),
          Text(
            isArchive ? 'Архив пуст' : 'Питомцев пока нет',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            isArchive
                ? 'Заархивированные карточки появятся здесь. Их можно вернуть в активные.'
                : 'Добавьте питомца или примите приглашение по коду, чтобы увидеть карточки.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetsCardsLayout extends StatelessWidget {
  const _PetsCardsLayout({
    required this.items,
    required this.itemBuilder,
  });

  final List<PetListEntry> items;
  final Widget Function(PetListEntry item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= 680;
        final spacing = useGrid ? PawlySpacing.md : PawlySpacing.md;
        final cardWidth = useGrid
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: itemBuilder(item),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _PetListCard extends StatelessWidget {
  const _PetListCard({
    required this.entry,
    this.onTap,
    this.onRestore,
  });

  final PetListEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final restore = onRestore;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.82),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PawlySpacing.md,
              vertical: PawlySpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _PetAvatar(
                  petId: entry.pet.id,
                  photoFileId: entry.pet.profilePhotoFileId,
                  photoUrl: entry.photoUrl,
                ),
                const SizedBox(width: PawlySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: PawlySpacing.xxs),
                      Text(
                        entry.speciesName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: PawlySpacing.xxs),
                      _PetRoleCaption(entry: entry),
                      if (entry.pet.status == 'ARCHIVED') ...<Widget>[
                        const SizedBox(height: PawlySpacing.xs),
                        Wrap(
                          spacing: PawlySpacing.xs,
                          runSpacing: PawlySpacing.xs,
                          children: <Widget>[
                            const PawlyBadge(
                              label: 'В архиве',
                              tone: PawlyBadgeTone.warning,
                            ),
                            if (entry.pet.archivedAt != null)
                              Text(
                                'с ${_formatShortDate(entry.pet.archivedAt!)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                if (restore != null)
                  _PetRoundActionButton(
                    icon: Icons.unarchive_rounded,
                    tooltip: 'Вернуть в активные',
                    onPressed: restore,
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                    size: 26,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetRoleCaption extends StatelessWidget {
  const _PetRoleCaption({required this.entry});

  final PetListEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      _petRoleCaption(entry),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.2,
      ),
    );
  }
}

class _PetRoundActionButton extends StatelessWidget {
  const _PetRoundActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 42,
        height: 42,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
            foregroundColor: colorScheme.onSurfaceVariant,
            side: BorderSide(
              color: colorScheme.outlineVariant,
            ),
          ),
          icon: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({
    required this.petId,
    required this.photoFileId,
    required this.photoUrl,
  });

  final String petId;
  final String? photoFileId;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final resolvedPhotoUrl =
        hasPhoto ? _normalizePetStorageUrl(photoUrl!) : null;

    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.surface,
          width: 2,
        ),
        color: colorScheme.onSurface.withValues(alpha: 0.06),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? PawlyCachedImage(
                imageUrl: resolvedPhotoUrl!,
                cacheKey: pawlyStableImageCacheKey(
                  scope: 'pet-avatar',
                  entityId: photoFileId ?? petId,
                  imageUrl: resolvedPhotoUrl,
                ),
                targetLogicalSize: 78,
                fit: BoxFit.cover,
                errorWidget: (_) => _PetAvatarFallback(
                  colorScheme: colorScheme,
                  iconSize: 34,
                ),
              )
            : _PetAvatarFallback(colorScheme: colorScheme, iconSize: 34),
      ),
    );
  }
}

class _PetAvatarFallback extends StatelessWidget {
  const _PetAvatarFallback({
    required this.colorScheme,
    this.iconSize = 46,
  });

  final ColorScheme colorScheme;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.pets_rounded,
        size: iconSize,
        color: colorScheme.primary,
      ),
    );
  }
}

class _PetFeatureCard extends StatelessWidget {
  const _PetFeatureCard({
    required this.title,
    required this.icon,
    this.tint,
    this.onTap,
    this.statusLabel,
  });

  final String title;
  final IconData icon;
  final Color? tint;
  final VoidCallback? onTap;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = tint ?? colorScheme.primary;
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: Ink(
          padding: const EdgeInsets.all(PawlySpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(PawlyRadius.md),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isEnabled
                          ? accent
                          : colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.54,
                            ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isEnabled
                        ? Icons.arrow_outward_rounded
                        : Icons.lock_outline_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: isEnabled ? 1 : 0.54,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              if (statusLabel != null && statusLabel!.isNotEmpty) ...<Widget>[
                const SizedBox(height: PawlySpacing.xxxs),
                Text(
                  statusLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PetWideFeatureCard extends StatelessWidget {
  const _PetWideFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.tint,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = tint ?? colorScheme.primary;
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: Ink(
          padding: const EdgeInsets.all(PawlySpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(PawlyRadius.md),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: isEnabled
                      ? accent
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.54),
                ),
              ),
              const SizedBox(width: PawlySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEnabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xxxs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              Icon(
                isEnabled
                    ? Icons.arrow_outward_rounded
                    : Icons.lock_outline_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(
                  alpha: isEnabled ? 1 : 0.54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePetView extends ConsumerWidget {
  const _ActivePetView({required this.entry});

  final PetListEntry? entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petDetailsAsync = ref.watch(activePetDetailsControllerProvider);

    return petDetailsAsync.when(
      data: (details) {
        if (details == null) {
          return _PetsErrorView(
            message: 'Активный питомец не найден.',
            onRetry: () =>
                ref.read(activePetControllerProvider.notifier).clear(),
          );
        }

        final pet = details.pet;
        final access = entry?.accessPolicy ??
            const PetAccessPolicy(permissions: <String, bool>{});
        final ageLabel = _petAgeLabel(pet.birthDate);
        final documentsCountAsync = access.documentsRead
            ? ref.watch(petDocumentsSummaryProvider(pet.id))
            : const AsyncValue<String>.data('Нет доступа');

        return ListView(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          children: <Widget>[
            _ActivePetHeroCard(
              pet: pet,
              speciesName: details.speciesName,
              ageLabel: ageLabel,
              isUploadingPhoto: details.isUploadingPhoto,
              onPhotoTap: details.isUploadingPhoto || !access.petWrite
                  ? null
                  : () => _showPhotoActionsSheet(context, ref, pet),
              onEdit: access.petWrite
                  ? () => context.pushNamed(
                        'petEdit',
                        pathParameters: {'petId': pet.id},
                      )
                  : null,
              onMore: () => _showActivePetActionsSheet(
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
                _PetFeatureCard(
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
                _PetFeatureCard(
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
                _PetFeatureCard(
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
                _PetFeatureCard(
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
            _PetWideFeatureCard(
              title: 'Напоминания',
              subtitle: '',
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
            _PetWideFeatureCard(
              title: 'Документы',
              subtitle: documentsCountAsync.maybeWhen(
                data: (value) => value,
                orElse: () => access.documentsRead
                    ? 'Все файлы питомца в одном месте'
                    : 'Нет доступа',
              ),
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
      error: (_, __) => _PetsErrorView(
        message: 'Не удалось загрузить карточку питомца.',
        onRetry: () =>
            ref.read(activePetDetailsControllerProvider.notifier).reload(),
      ),
    );
  }
}

class _ActivePetHeroCard extends StatelessWidget {
  const _ActivePetHeroCard({
    required this.pet,
    required this.speciesName,
    required this.ageLabel,
    required this.isUploadingPhoto,
    this.onPhotoTap,
    this.onEdit,
    required this.onMore,
  });

  final Pet pet;
  final String speciesName;
  final String ageLabel;
  final bool isUploadingPhoto;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onEdit;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _HeroPetAvatar(
              petId: pet.id,
              photoFileId: pet.profilePhotoFileId,
              photoUrl: pet.profilePhotoDownloadUrl,
              isUploadingPhoto: isUploadingPhoto,
              onTap: onPhotoTap,
            ),
            const SizedBox(width: PawlySpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: PawlySpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xs),
                    Text(
                      '$speciesName · $ageLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _HeroCompactActionButton(
                  onPressed: onEdit,
                  icon: Icons.edit_rounded,
                  tooltip: 'Редактировать питомца',
                ),
                const SizedBox(height: PawlySpacing.xs),
                _HeroCompactActionButton(
                  onPressed: onMore,
                  icon: Icons.more_horiz_rounded,
                  tooltip: 'Действия',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPetAvatar extends StatelessWidget {
  const _HeroPetAvatar({
    required this.petId,
    required this.photoFileId,
    required this.photoUrl,
    required this.isUploadingPhoto,
    this.onTap,
  });

  final String petId;
  final String? photoFileId;
  final String? photoUrl;
  final bool isUploadingPhoto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final resolvedPhotoUrl =
        hasPhoto ? _normalizePetStorageUrl(photoUrl!) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface,
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (hasPhoto)
                PawlyCachedImage(
                  imageUrl: resolvedPhotoUrl!,
                  cacheKey: pawlyStableImageCacheKey(
                    scope: 'pet-avatar',
                    entityId: photoFileId ?? petId,
                    imageUrl: resolvedPhotoUrl,
                  ),
                  targetLogicalSize: 108,
                  fit: BoxFit.cover,
                  errorWidget: (_) =>
                      _PetAvatarFallback(colorScheme: colorScheme),
                )
              else
                _PetAvatarFallback(colorScheme: colorScheme),
              if (isUploadingPhoto)
                Container(
                  color: Colors.black.withValues(alpha: 0.30),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
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

class _HeroCompactActionButton extends StatelessWidget {
  const _HeroCompactActionButton({
    this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 38,
        height: 38,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurfaceVariant,
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          iconSize: 18,
          icon: Icon(icon),
        ),
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

String _normalizePetStorageUrl(String url) {
  final uri = Uri.tryParse(url);
  final apiUri = Uri.tryParse(ApiConstants.baseUrl);
  if (uri == null || apiUri == null || uri.host != 'minio') {
    return url;
  }

  return uri.replace(host: apiUri.host).toString();
}

PetListEntry? _petListEntryById(List<PetListEntry> items, String petId) {
  for (final item in items) {
    if (item.id == petId) {
      return item;
    }
  }
  return null;
}

Future<void> _archiveActivePet(
  BuildContext context,
  WidgetRef ref,
  String petName,
) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Архивировать питомца?'),
          content: Text(
            '$petName исчезнет из списка активных питомцев и будет доступен в архиве.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Архивировать'),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) {
    return;
  }

  try {
    await ref.read(activePetDetailsControllerProvider.notifier).archivePet();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$petName перемещен в архив.'),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Не удалось архивировать питомца.',
          ),
        ),
      );
    }
  }
}

Future<void> _showActivePetActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String petName,
  required bool canArchive,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(PawlyRadius.xl)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PawlySpacing.md,
            PawlySpacing.md,
            PawlySpacing.md,
            PawlySpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: const Text('Сменить питомца'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await ref.read(activePetControllerProvider.notifier).clear();
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                iconColor: Theme.of(context).colorScheme.error,
                textColor: Theme.of(context).colorScheme.error,
                title: const Text('Архивировать питомца'),
                enabled: canArchive,
                subtitle:
                    canArchive ? null : const Text('Редактирование недоступно'),
                onTap: canArchive
                    ? () async {
                        Navigator.of(sheetContext).pop();
                        await _archiveActivePet(context, ref, petName);
                      }
                    : null,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _restorePetFromArchive(
  BuildContext context,
  WidgetRef ref,
  Pet pet,
) async {
  try {
    await ref.read(petsControllerProvider.notifier).changePetStatus(
          pet: pet,
          status: 'ACTIVE',
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pet.name} возвращен в активные.'),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Не удалось вернуть питомца из архива.',
          ),
        ),
      );
    }
  }
}

String _petAgeLabel(DateTime? birthDate) {
  if (birthDate == null) {
    return 'возраст неизвестен';
  }

  final now = DateTime.now();
  var years = now.year - birthDate.year;
  var months = now.month - birthDate.month;

  if (now.day < birthDate.day) {
    months -= 1;
  }

  if (months < 0) {
    years -= 1;
    months += 12;
  }

  if (years > 0) {
    return '$years ${_yearsWord(years)}';
  }
  if (months > 0) {
    return '$months ${_monthsWord(months)}';
  }
  return 'меньше месяца';
}

String _yearsWord(int value) {
  final mod10 = value % 10;
  final mod100 = value % 100;
  if (mod10 == 1 && mod100 != 11) {
    return 'год';
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'года';
  }
  return 'лет';
}

String _monthsWord(int value) {
  final mod10 = value % 10;
  final mod100 = value % 100;
  if (mod10 == 1 && mod100 != 11) {
    return 'месяц';
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'месяца';
  }
  return 'месяцев';
}

String _formatShortDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day.$month.$year';
}

String _petsCountLabel(int value) {
  final mod10 = value % 10;
  final mod100 = value % 100;
  final word = mod10 == 1 && mod100 != 11
      ? 'карточка'
      : mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)
          ? 'карточки'
          : 'карточек';
  return '$value $word';
}

String _petRoleCaption(PetListEntry entry) {
  final roleTitle = _localizedPetRoleTitle(entry.roleTitle);
  return 'Роль: $roleTitle';
}

String _localizedPetRoleTitle(String rawTitle) {
  final normalized = rawTitle.trim();
  final upper = normalized.toUpperCase();
  return switch (normalized) {
    _ => switch (upper) {
        'OWNER' => 'Владелец',
        'CO_OWNER' || 'CO-OWNER' => 'Совладелец',
        'VET' || 'VETERINARY' => 'Ветеринар',
        'PETSITTER' || 'PETSITTER ' => 'Петситтер',
        'WALKER' => 'Выгульщик',
        _ => normalized,
      },
  };
}

Future<void> _showPhotoActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Pet pet,
) async {
  final hasPhoto = (pet.profilePhotoFileId ?? '').isNotEmpty ||
      (pet.profilePhotoDownloadUrl ?? '').isNotEmpty;
  final pageContext = context;

  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(PawlyRadius.xl)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PawlySpacing.md,
            PawlySpacing.md,
            PawlySpacing.md,
            PawlySpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Выбрать из галереи'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _uploadPetPhotoFromGallery(pageContext, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Сделать фото'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _uploadPetPhotoFromCamera(pageContext, ref);
                },
              ),
              if (hasPhoto) ...<Widget>[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Удалить фото',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _deletePetPhoto(pageContext, ref);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _uploadPetPhotoFromGallery(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    await ref
        .read(activePetDetailsControllerProvider.notifier)
        .uploadPhotoFromGallery();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Не удалось установить фото питомца.',
          ),
        ),
      );
    }
  }
}

Future<void> _uploadPetPhotoFromCamera(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    await ref
        .read(activePetDetailsControllerProvider.notifier)
        .uploadPhotoFromCamera();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Не удалось установить фото питомца.',
          ),
        ),
      );
    }
  }
}

Future<void> _deletePetPhoto(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    await ref.read(activePetDetailsControllerProvider.notifier).deletePhoto();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Не удалось удалить фото питомца.',
          ),
        ),
      );
    }
  }
}

class _PetsActionsButton extends StatelessWidget {
  const _PetsActionsButton({
    required this.onCreatePet,
    required this.onJoinByCode,
  });

  final VoidCallback onCreatePet;
  final VoidCallback onJoinByCode;

  @override
  Widget build(BuildContext context) {
    return PawlyAddActionButton(
      label: 'Добавить',
      tooltip: 'Добавить питомца',
      onTap: () => _showPetsActionsSheet(context),
    );
  }

  Future<void> _showPetsActionsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(PawlyRadius.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PawlySpacing.md,
              PawlySpacing.md,
              PawlySpacing.md,
              PawlySpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.pets_rounded),
                  title: const Text('Создать питомца'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onCreatePet();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.key_rounded),
                  title: const Text('По коду'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onJoinByCode();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PetsErrorView extends StatelessWidget {
  const _PetsErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: Text(message),
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

Future<void> _showJoinByCodeDialog(BuildContext context, WidgetRef ref) async {
  final acceptedPetId = await showDialog<String>(
    context: context,
    builder: (_) => const _JoinByCodeDialog(),
  );

  if (acceptedPetId == null || !context.mounted) {
    return;
  }

  try {
    await ref.read(activePetControllerProvider.notifier).selectPet(
          acceptedPetId,
        );
    ref.invalidate(activePetDetailsControllerProvider);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _acceptInviteByCodeErrorMessage(error),
          ),
        ),
      );
    }
  }
}

class _JoinByCodeDialog extends ConsumerStatefulWidget {
  const _JoinByCodeDialog();

  @override
  ConsumerState<_JoinByCodeDialog> createState() => _JoinByCodeDialogState();
}

class _JoinByCodeDialogState extends ConsumerState<_JoinByCodeDialog> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Присоединиться по коду'),
      content: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.characters,
        maxLength: 6,
        decoration: const InputDecoration(
          hintText: 'Введите код',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isSubmitting ? 'Подключаем...' : 'Подключиться'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Код должен содержать 6 символов.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final petId = await ref
          .read(petsControllerProvider.notifier)
          .acceptInviteByCode(code);
      await ref.read(petsControllerProvider.notifier).reload();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(petId);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _acceptInviteByCodeErrorMessage(error),
          ),
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

String _acceptInviteByCodeErrorMessage(Object error) {
  if (error is StateError) {
    return error.message.toString();
  }
  return 'Не удалось присоединиться по коду.';
}
