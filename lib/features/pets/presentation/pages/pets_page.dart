import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../data/pets_repository.dart';
import '../providers/active_pet_controller.dart';
import '../providers/pets_controller.dart';

class PetsPage extends ConsumerWidget {
  const PetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePetAsync = ref.watch(activePetControllerProvider);
    final petsStateAsync = ref.watch(petsControllerProvider);
    final activePetId = activePetAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Питомцы')),
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

              final activeEntry = _findActiveEntry(
                items: petsState.items,
                activePetId: activePetId,
              );

              return _ActivePetView(
                activePetId: activePetId,
                activeEntry: activeEntry,
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

PetListEntry? _findActiveEntry({
  required List<PetListEntry> items,
  required String activePetId,
}) {
  for (final item in items) {
    if (item.id == activePetId) {
      return item;
    }
  }
  return null;
}

class _PetsListView extends ConsumerWidget {
  const _PetsListView({required this.state});

  final PetsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = state.filteredItems;

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        TextField(
          onChanged: (value) {
            ref.read(petsControllerProvider.notifier).setSearchQuery(value);
          },
          decoration: const InputDecoration(
            hintText: 'Поиск питомца по имени',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        Text(
          'Доступные питомцы',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: PawlySpacing.sm),
        Wrap(
          spacing: PawlySpacing.xs,
          runSpacing: PawlySpacing.xs,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Все'),
              selected: state.ownershipFilter == PetsOwnershipFilter.all,
              onSelected: (_) {
                ref
                    .read(petsControllerProvider.notifier)
                    .setOwnershipFilter(PetsOwnershipFilter.all);
              },
            ),
            ChoiceChip(
              label: const Text('Мои'),
              selected: state.ownershipFilter == PetsOwnershipFilter.owned,
              onSelected: (_) {
                ref
                    .read(petsControllerProvider.notifier)
                    .setOwnershipFilter(PetsOwnershipFilter.owned);
              },
            ),
            ChoiceChip(
              label: const Text('Не мои'),
              selected: state.ownershipFilter == PetsOwnershipFilter.shared,
              onSelected: (_) {
                ref
                    .read(petsControllerProvider.notifier)
                    .setOwnershipFilter(PetsOwnershipFilter.shared);
              },
            ),
          ],
        ),
        const SizedBox(height: PawlySpacing.lg),
        if (items.isEmpty)
          PawlyCard(
            title: Text('Питомцев пока нет', style: theme.textTheme.titleLarge),
            child: Text(
              'Когда появятся питомцы, здесь будет список карточек. Добавить питомца можно через кнопку внизу.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: PawlySpacing.md),
              child: _PetListCard(
                entry: item,
                onTap: () =>
                    ref.read(activePetControllerProvider.notifier).selectPet(
                          item.id,
                        ),
              ),
            );
          }),
        const SizedBox(height: 96),
      ],
    );
  }
}

class _PetListCard extends StatelessWidget {
  const _PetListCard({
    required this.entry,
    required this.onTap,
  });

  final PetListEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
            border: Border.all(color: colorScheme.outline),
            boxShadow: PawlyElevation.soft(colorScheme.shadow),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _PetAvatar(photoUrl: entry.photoUrl),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: PawlySpacing.xxs),
                      Text(
                        entry.speciesName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: PawlySpacing.xs),
                      Text(
                        'Роль: ${entry.roleTitle}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.onSurface, width: 2.2),
        color: colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _PetAvatarFallback(
                colorScheme: colorScheme,
              ),
            )
          : _PetAvatarFallback(colorScheme: colorScheme),
    );
  }
}

class _PetAvatarFallback extends StatelessWidget {
  const _PetAvatarFallback({
    required this.colorScheme,
  });

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.pets_rounded,
        size: 46,
        color: colorScheme.primary,
      ),
    );
  }
}

class _ActivePetView extends ConsumerWidget {
  const _ActivePetView({
    required this.activePetId,
    required this.activeEntry,
  });

  final String activePetId;
  final PetListEntry? activeEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entry = activeEntry;

    if (entry == null) {
      return Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: Text('Активный питомец не найден',
              style: theme.textTheme.titleLarge),
          footer: PawlyButton(
            label: 'Сбросить активного питомца',
            onPressed: () =>
                ref.read(activePetControllerProvider.notifier).clear(),
            variant: PawlyButtonVariant.secondary,
          ),
          child: Text(
            'В storage сохранен id `$activePetId`, но в текущем списке питомцев его нет.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        PawlyCard(
          title: Text(entry.name, style: theme.textTheme.headlineSmall),
          trailing: Chip(label: Text(entry.roleTitle)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(entry.speciesName, style: theme.textTheme.titleMedium),
              const SizedBox(height: PawlySpacing.sm),
              Text(
                entry.isOwnedByMe
                    ? 'Активный питомец принадлежит вам.'
                    : 'Активный питомец доступен вам по роли.',
                style: theme.textTheme.bodyMedium,
              ),
              if (entry.photoUrl != null &&
                  entry.photoUrl!.isNotEmpty) ...<Widget>[
                const SizedBox(height: PawlySpacing.md),
                Text(
                  'Фото уже доступно в API и будет подключено на следующем шаге.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        PawlyButton(
          label: 'Сменить питомца',
          onPressed: () =>
              ref.read(activePetControllerProvider.notifier).clear(),
          variant: PawlyButtonVariant.secondary,
        ),
      ],
    );
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
    return FloatingActionButton(
      onPressed: () => _showPetsActionsSheet(context),
      child: const Icon(Icons.add_rounded),
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
  final controller = TextEditingController();
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Присоединиться по коду'),
            content: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'Введите код',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final code = controller.text.trim().toUpperCase();
                        if (code.length != 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Код должен содержать 6 символов.'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          isSubmitting = true;
                        });

                        try {
                          final petId = await ref
                              .read(petsControllerProvider.notifier)
                              .acceptInviteByCode(code);
                          await ref
                              .read(activePetControllerProvider.notifier)
                              .selectPet(petId);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Не удалось присоединиться по коду.'),
                              ),
                            );
                          }
                          setState(() {
                            isSubmitting = false;
                          });
                        }
                      },
                child: Text(isSubmitting ? 'Подключаем...' : 'Подключиться'),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
}
