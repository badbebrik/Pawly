import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/network/models/acl_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../pets/presentation/providers/active_pet_controller.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../models/acl_screen_models.dart';
import '../providers/acl_controllers.dart';

class AclInvitePreviewPage extends ConsumerWidget {
  const AclInvitePreviewPage({
    required this.token,
    super.key,
  });

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return PawlyScreenScaffold(
        title: 'Приглашение',
        body: _AclInvitePreviewErrorView(
          title: 'Ссылка приглашения недействительна',
          message: 'В ссылке отсутствует токен приглашения.',
          onRetry: null,
        ),
      );
    }

    final state = ref.watch(
      aclInvitePreviewControllerProvider(normalizedToken),
    );

    return PawlyScreenScaffold(
      title: 'Приглашение',
      body: state.when(
        data: (value) => _AclInvitePreviewContent(
          state: value,
          onAccept: () => _acceptInvite(context, ref, normalizedToken),
          onClose: () => _closePreview(context),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AclInvitePreviewErrorView(
          title: 'Не удалось открыть приглашение',
          message: _previewErrorMessage(error),
          onRetry: () => ref
              .read(
                aclInvitePreviewControllerProvider(normalizedToken).notifier,
              )
              .reload(),
        ),
      ),
    );
  }

  Future<void> _acceptInvite(
    BuildContext context,
    WidgetRef ref,
    String token,
  ) async {
    final currentUserId = await ref.read(currentUserIdProvider.future);
    if (currentUserId == null || currentUserId.isEmpty) {
      if (!context.mounted) {
        return;
      }
      final redirectLocation = Uri(
        path: AppRoutes.aclInvitePreview,
        queryParameters: <String, String>{'token': token},
      ).toString();
      context.push(
        Uri(
          path: AppRoutes.login,
          queryParameters: <String, String>{'redirect': redirectLocation},
        ).toString(),
      );
      return;
    }

    try {
      final response = await ref
          .read(aclInvitePreviewControllerProvider(token).notifier)
          .accept();
      await ref.read(petsControllerProvider.notifier).reload();
      await ref
          .read(activePetControllerProvider.notifier)
          .selectPet(response.petId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Вы присоединились как ${_localizedRoleTitle(response.member.role)}.',
          ),
        ),
      );
      context.go(AppRoutes.pets);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_acceptErrorMessage(error)),
        ),
      );
    }
  }

  void _closePreview(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.pets);
  }
}

class _AclInvitePreviewContent extends StatelessWidget {
  const _AclInvitePreviewContent({
    required this.state,
    required this.onAccept,
    required this.onClose,
  });

  final AclInvitePreviewState state;
  final Future<void> Function() onAccept;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final invite = state.invite;
    final pet = state.pet;
    final permissions = AclPermissionDraft.fromPolicy(invite.policy);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        _InvitePetHeaderCard(
          pet: pet,
          roleTitle: _localizedRoleTitle(invite.role),
        ),
        const SizedBox(height: PawlySpacing.md),
        _InvitePreviewSection(
          title: 'Доступ',
          child: Column(
            children: <Widget>[
              _InviteMetaRow(
                  label: 'Роль', value: _localizedRoleTitle(invite.role)),
              const Divider(height: PawlySpacing.lg),
              _InviteMetaRow(label: 'Код', value: invite.code),
              if (invite.expiresAt != null) ...<Widget>[
                const Divider(height: PawlySpacing.lg),
                _InviteMetaRow(
                  label: 'Срок действия',
                  value: _formatInviteExpiry(invite.expiresAt!),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        _InvitePreviewSection(
          title: 'Права доступа',
          child: _ReadOnlyPermissionsList(draft: permissions),
        ),
        const SizedBox(height: PawlySpacing.xl),
        PawlyButton(
          label: state.isSubmitting ? 'Подключаем...' : 'Принять приглашение',
          onPressed: state.isSubmitting ? null : onAccept,
        ),
        const SizedBox(height: PawlySpacing.sm),
        PawlyButton(
          label: 'Закрыть',
          onPressed: state.isSubmitting ? null : onClose,
          variant: PawlyButtonVariant.secondary,
        ),
      ],
    );
  }
}

class _InvitePetHeaderCard extends StatelessWidget {
  const _InvitePetHeaderCard({
    required this.pet,
    required this.roleTitle,
  });

  final AclInvitePreviewPet pet;
  final String roleTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
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
          children: <Widget>[
            _InvitePetAvatar(
              photoUrl: pet.photoDownloadUrl,
              name: pet.name,
            ),
            const SizedBox(width: PawlySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pet.name.isEmpty ? 'Питомец' : pet.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.xxs),
                  Text(
                    roleTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitePreviewSection extends StatelessWidget {
  const _InvitePreviewSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PawlySpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _InvitePetAvatar extends StatelessWidget {
  const _InvitePetAvatar({
    required this.photoUrl,
    required this.name,
  });

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = photoUrl;
    final initial = name.trim().isEmpty ? 'P' : name.trim().characters.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(PawlyRadius.lg),
      child: Container(
        width: 68,
        height: 68,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        child: url == null || url.isEmpty
            ? _InvitePetInitial(initial: initial)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                errorWidget: (_, __, ___) =>
                    _InvitePetInitial(initial: initial),
              ),
      ),
    );
  }
}

class _InvitePetInitial extends StatelessWidget {
  const _InvitePetInitial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Text(
        initial.toUpperCase(),
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InviteMetaRow extends StatelessWidget {
  const _InviteMetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: PawlySpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyPermissionsList extends StatelessWidget {
  const _ReadOnlyPermissionsList({required this.draft});

  final AclPermissionDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: draft.items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.42,
              ),
              borderRadius: BorderRadius.circular(PawlyRadius.lg),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.64),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(PawlySpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _domainLabel(item.domain),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: PawlySpacing.sm),
                  Flexible(
                    child: Text(
                      _permissionLabel(item),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _AclInvitePreviewErrorView extends StatelessWidget {
  const _AclInvitePreviewErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

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
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (onRetry != null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.md),
                  PawlyButton(
                    label: 'Повторить',
                    onPressed: onRetry,
                    variant: PawlyButtonVariant.secondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _localizedRoleTitle(AclRole role) {
  return switch (role.code) {
    'OWNER' => 'Владелец',
    'CO_OWNER' => 'Совладелец',
    'VET' => 'Ветеринар',
    'PETSITTER' => 'Петситтер',
    'WALKER' => 'Выгул',
    _ => role.title,
  };
}

String _domainLabel(AclPermissionDomain domain) {
  return switch (domain) {
    AclPermissionDomain.pet => 'Питомец',
    AclPermissionDomain.log => 'Записи',
    AclPermissionDomain.health => 'Здоровье',
    AclPermissionDomain.members => 'Участники',
  };
}

String _permissionLabel(AclPermissionSelection item) {
  if (item.canWrite) {
    return 'Просмотр и изменение';
  }
  if (item.canRead) {
    return 'Только просмотр';
  }
  return 'Нет доступа';
}

String _formatInviteExpiry(DateTime value) {
  final date = '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.'
      '${value.year}';
  final time = '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
  return '$date в $time';
}

String _previewErrorMessage(Object error) {
  if (error is StateError) {
    return error.message.toString();
  }
  return 'Проверьте ссылку или попробуйте открыть приглашение позже.';
}

String _acceptErrorMessage(Object error) {
  if (error is StateError) {
    return error.message.toString();
  }
  return 'Не удалось присоединиться к питомцу по приглашению.';
}
