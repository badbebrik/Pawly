import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      return Scaffold(
        appBar: AppBar(title: const Text('Приглашение к питомцу')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Приглашение к питомцу')),
      body: state.when(
        data: (value) => _AclInvitePreviewContent(
          state: value,
          onAccept: () => _acceptInvite(context, ref, normalizedToken),
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
}

class _AclInvitePreviewContent extends StatelessWidget {
  const _AclInvitePreviewContent({
    required this.state,
    required this.onAccept,
  });

  final AclInvitePreviewState state;
  final Future<void> Function() onAccept;

  @override
  Widget build(BuildContext context) {
    final invite = state.invite;
    final permissions = AclPermissionDraft.fromPolicy(invite.policy);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Вас приглашают к уходу за питомцем',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: PawlySpacing.sm),
              Text(
                'Перед вступлением проверьте роль, код и набор прав.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.lg),
        Text(
          'Роль',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        PawlyCard(
          child: Text(
            _localizedRoleTitle(invite.role),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: PawlySpacing.lg),
        Text(
          'Код',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        PawlyCard(
          child: Text(
            invite.code,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (invite.expiresAt != null) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          Text(
            'Срок действия',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          PawlyCard(
            child: Text(
              _formatInviteExpiry(invite.expiresAt!),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const SizedBox(height: PawlySpacing.lg),
        Text(
          'Права',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        _ReadOnlyPermissionsTable(draft: permissions),
        const SizedBox(height: PawlySpacing.xl),
        PawlyButton(
          label: state.isSubmitting ? 'Подключаем...' : 'Присоединиться',
          onPressed: state.isSubmitting ? null : onAccept,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }
}

class _ReadOnlyPermissionsTable extends StatelessWidget {
  const _ReadOnlyPermissionsTable({required this.draft});

  final AclPermissionDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PawlyCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PawlySpacing.md,
              vertical: PawlySpacing.sm,
            ),
            decoration: BoxDecoration(
              color:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(PawlyRadius.lg),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Text(
                    'Домен',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Просмотр',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Изменение',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...draft.items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: PawlySpacing.md,
                vertical: PawlySpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Text(
                      _domainLabel(item.domain),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(
                        item.canRead
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: item.canRead
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(
                        item.canWrite
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: item.canWrite
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: Text(title),
          footer: onRetry == null
              ? null
              : PawlyButton(
                  label: 'Повторить',
                  onPressed: onRetry,
                  variant: PawlyButtonVariant.secondary,
                ),
          child: Text(message),
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
