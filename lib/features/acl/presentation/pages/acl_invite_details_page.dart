import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/models/acl_models.dart';
import '../../../../design_system/design_system.dart';
import '../models/acl_screen_models.dart';
import '../providers/acl_controllers.dart';

class AclInviteDetailsPage extends ConsumerWidget {
  const AclInviteDetailsPage({
    required this.petId,
    required this.inviteId,
    super.key,
  });

  final String petId;
  final String inviteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      aclInviteDetailsControllerProvider(
        AclInviteRef(petId: petId, inviteId: inviteId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Приглашение'),
        actions: <Widget>[
          IconButton(
            onPressed: () => _editInvite(context),
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Редактировать',
          ),
          IconButton(
            onPressed: () => _deleteInvite(context, ref),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Удалить',
          ),
        ],
      ),
      body: state.when(
        data: (value) => _AclInviteDetailsContent(state: value),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _AclInviteDetailsErrorView(
          onRetry: () => ref
              .read(
                aclInviteDetailsControllerProvider(
                  AclInviteRef(petId: petId, inviteId: inviteId),
                ).notifier,
              )
              .reload(),
        ),
      ),
    );
  }

  Future<void> _editInvite(BuildContext context) async {
    final nextInviteId = await context.pushNamed<String>(
      'aclInviteEdit',
      pathParameters: <String, String>{
        'petId': petId,
        'inviteId': inviteId,
      },
    );
    if (nextInviteId == null || !context.mounted) {
      return;
    }

    context.pushReplacementNamed(
      'aclInviteDetails',
      pathParameters: <String, String>{
        'petId': petId,
        'inviteId': nextInviteId,
      },
    );
  }

  Future<void> _deleteInvite(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Удалить приглашение?'),
            content: const Text(
              'Ссылка и код перестанут работать для новых участников.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Удалить'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(
            aclInviteDetailsControllerProvider(
              AclInviteRef(petId: petId, inviteId: inviteId),
            ).notifier,
          )
          .revokeInvite();
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Не удалось удалить приглашение.',
          ),
        ),
      );
    }
  }
}

class _AclInviteDetailsContent extends StatelessWidget {
  const _AclInviteDetailsContent({required this.state});

  final AclInviteDetailsState state;

  @override
  Widget build(BuildContext context) {
    final invite = state.invite;
    final permissions = AclPermissionDraft.fromPolicy(invite.policy);

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        Text(
          'Ссылка',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: PawlySpacing.md),
        _CopyValueCard(
          value: invite.deeplinkUrl ?? 'Ссылка недоступна',
          onCopy: invite.deeplinkUrl == null
              ? null
              : () => _copyText(
                    context,
                    invite.deeplinkUrl!,
                    'Ссылка приглашения скопирована.',
                  ),
        ),
        const SizedBox(height: PawlySpacing.sm),
        PawlyButton(
          label: 'Поделиться ссылкой',
          onPressed: invite.deeplinkUrl == null
              ? null
              : () => _shareLink(
                    context,
                    invite.deeplinkUrl!,
                  ),
          variant: PawlyButtonVariant.secondary,
          icon: Icons.ios_share_rounded,
        ),
        const SizedBox(height: PawlySpacing.lg),
        Text(
          'Код',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: PawlySpacing.md),
        _CopyValueCard(
          value: invite.code,
          onCopy: () => _copyText(
            context,
            invite.code,
            'Код приглашения скопирован.',
          ),
        ),
        const SizedBox(height: PawlySpacing.lg),
        Text(
          'Роль',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: PawlySpacing.md),
        PawlyCard(
          child: Text(
            _localizedRoleTitle(invite.role),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: PawlySpacing.lg),
        Text(
          'Права',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: PawlySpacing.md),
        _ReadOnlyPermissionsTable(draft: permissions),
      ],
    );
  }

  Future<void> _copyText(
    BuildContext context,
    String value,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _shareLink(
    BuildContext context,
    String url,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      url,
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
    if (!context.mounted) {
      return;
    }
  }
}

class _CopyValueCard extends StatelessWidget {
  const _CopyValueCard({
    required this.value,
    this.onCopy,
  });

  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PawlyCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: PawlySpacing.md),
          IconButton.outlined(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Копировать',
          ),
        ],
      ),
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

class _AclInviteDetailsErrorView extends StatelessWidget {
  const _AclInviteDetailsErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить приглашение'),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: const Text(
            'Попробуйте открыть приглашение снова чуть позже.',
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
