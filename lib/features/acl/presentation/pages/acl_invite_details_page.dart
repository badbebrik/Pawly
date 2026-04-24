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

    return PawlyScreenScaffold(
      title: 'Приглашение',
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
      pathParameters: <String, String>{'petId': petId, 'inviteId': inviteId},
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
    final deeplinkUrl = invite.deeplinkUrl;
    final hasLink = deeplinkUrl != null && deeplinkUrl.isNotEmpty;
    final permissions = AclPermissionDraft.fromPolicy(invite.policy);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        _InviteSummaryCard(invite: invite),
        const SizedBox(height: PawlySpacing.md),
        _InviteDetailsSection(
          title: 'Ссылка',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _InviteValueTile(
                value: hasLink ? deeplinkUrl : 'Ссылка недоступна',
                isMuted: !hasLink,
                onCopy: hasLink
                    ? () => _copyText(
                          context,
                          deeplinkUrl,
                          'Ссылка приглашения скопирована.',
                        )
                    : null,
              ),
              const SizedBox(height: PawlySpacing.sm),
              PawlyButton(
                label: 'Поделиться ссылкой',
                onPressed:
                    hasLink ? () => _shareLink(context, deeplinkUrl) : null,
                variant: PawlyButtonVariant.secondary,
                icon: Icons.ios_share_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        _InviteDetailsSection(
          title: 'Код',
          child: _InviteValueTile(
            value: invite.code,
            isCode: true,
            onCopy: () =>
                _copyText(context, invite.code, 'Код приглашения скопирован.'),
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        _InviteDetailsSection(
          title: 'Права доступа',
          child: _ReadOnlyPermissionsList(draft: permissions),
        ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _shareLink(BuildContext context, String url) async {
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

class _InviteSummaryCard extends StatelessWidget {
  const _InviteSummaryCard({required this.invite});

  final AclInvite invite;

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
              'Доступ по приглашению',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: PawlySpacing.xxs),
            Text(
              'Роль: ${_localizedRoleTitle(invite.role)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: PawlySpacing.xxs),
            Text(
              _inviteMetaLabel(invite),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteDetailsSection extends StatelessWidget {
  const _InviteDetailsSection({required this.title, required this.child});

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

class _InviteValueTile extends StatelessWidget {
  const _InviteValueTile({
    required this.value,
    this.isCode = false,
    this.isMuted = false,
    this.onCopy,
  });

  final String value;
  final bool isCode;
  final bool isMuted;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.64),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.md,
          vertical: PawlySpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: SelectableText(
                value,
                style: (isCode
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                  color: isMuted
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                  fontWeight: isCode ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            _InviteCopyButton(onPressed: onCopy),
          ],
        ),
      ),
    );
  }
}

class _InviteCopyButton extends StatelessWidget {
  const _InviteCopyButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surface,
        disabledBackgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.36,
        ),
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.md),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.68),
          ),
        ),
      ),
      icon: const Icon(Icons.content_copy_rounded),
      tooltip: 'Копировать',
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

class _AclInviteDetailsErrorView extends StatelessWidget {
  const _AclInviteDetailsErrorView({required this.onRetry});

  final VoidCallback onRetry;

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
                  'Не удалось загрузить приглашение',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Попробуйте открыть приглашение снова чуть позже.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
      ),
    );
  }
}

String _inviteMetaLabel(AclInvite invite) {
  final expiresAt = invite.expiresAt;
  return expiresAt == null
      ? 'Без срока действия'
      : 'До ${_formatShortDate(expiresAt)}';
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

String _formatShortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
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
