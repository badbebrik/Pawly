import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/models/acl_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../chat/data/chat_repository_models.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../models/acl_screen_models.dart';
import '../providers/acl_controllers.dart';

class AclAccessPage extends ConsumerWidget {
  const AclAccessPage({required this.petId, super.key});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(aclAccessControllerProvider(petId));

    return PawlyScreenScaffold(
      title: 'Участники',
      body: accessState.when(
        data: (state) => _AclAccessContent(
          state: state,
          onMemberTap: (memberId) => context.pushNamed(
            'aclMemberDetails',
            pathParameters: <String, String>{
              'petId': petId,
              'memberId': memberId,
            },
          ),
          onCreateInvite: state.capabilities.membersWrite
              ? () => context.pushNamed(
                    'aclCreateInvite',
                    pathParameters: <String, String>{'petId': petId},
                  )
              : null,
          onInviteTap: (inviteId) => context.pushNamed(
            'aclInviteDetails',
            pathParameters: <String, String>{
              'petId': petId,
              'inviteId': inviteId,
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _AclAccessErrorView(
          onRetry: () =>
              ref.read(aclAccessControllerProvider(petId).notifier).reload(),
        ),
      ),
    );
  }
}

class _AclAccessContent extends StatelessWidget {
  const _AclAccessContent({
    required this.state,
    required this.onMemberTap,
    required this.onInviteTap,
    this.onCreateInvite,
  });

  final AclAccessScreenState state;
  final VoidCallback? onCreateInvite;
  final ValueChanged<String> onMemberTap;
  final ValueChanged<String> onInviteTap;

  @override
  Widget build(BuildContext context) {
    final members = state.membersForDisplay;
    final invites = state.activeInvites;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        _AclSectionHeader(title: 'Участники', count: members.length),
        const SizedBox(height: PawlySpacing.sm),
        if (members.isEmpty)
          const _AclEmptyCard(
            title: 'Участников пока нет',
            text: 'Здесь появятся люди, у которых есть доступ к питомцу.',
          )
        else
          ...members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
              child: _AclMemberTile(
                member: member,
                meUserId: state.me.userId,
                onTap: () => onMemberTap(member.id),
                onMessageTap: member.userId == state.me.userId
                    ? null
                    : () => _openDirectChat(
                          context: context,
                          ref: ProviderScope.containerOf(context),
                          petId: state.me.petId,
                          otherUserId: member.userId,
                        ),
              ),
            ),
          ),
        const SizedBox(height: PawlySpacing.md),
        _AclSectionHeader(
          title: 'Приглашения',
          count: invites.length,
          actionLabel: onCreateInvite == null ? null : 'Создать',
          onActionTap: onCreateInvite,
        ),
        const SizedBox(height: PawlySpacing.sm),
        if (invites.isEmpty)
          const _AclEmptyCard(
            title: 'Приглашений нет',
            text: 'Создайте приглашение, чтобы добавить нового участника.',
          )
        else
          ...invites.map(
            (invite) => Padding(
              padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
              child: _AclInviteTile(
                invite: invite,
                onTap: () => onInviteTap(invite.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _AclSectionHeader extends StatelessWidget {
  const _AclSectionHeader({
    required this.title,
    required this.count,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final int count;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null) ...[
          TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
          const SizedBox(width: PawlySpacing.xs),
        ],
        Text(
          '$count',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AclEmptyCard extends StatelessWidget {
  const _AclEmptyCard({required this.title, required this.text});

  final String title;
  final String text;

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
            const SizedBox(height: PawlySpacing.xs),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AclMemberTile extends StatelessWidget {
  const _AclMemberTile({
    required this.member,
    required this.meUserId,
    required this.onTap,
    this.onMessageTap,
  });

  final AclMember member;
  final String meUserId;
  final VoidCallback onTap;
  final VoidCallback? onMessageTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMe = member.userId == meUserId;
    final profile = member.profile;
    final fullName = _memberName(profile);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.xl),
      child: Ink(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _AclAvatar(
                userId: member.userId,
                photoUrl: profile?.avatarDownloadUrl,
                fallbackLabel: fullName,
                showCrown: member.isPrimaryOwner,
              ),
              const SizedBox(width: PawlySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xxs),
                    Text(
                      member.isPrimaryOwner
                          ? 'Роль: основной владелец'
                          : 'Роль: ${_localizedRoleTitle(member.role)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(height: PawlySpacing.xxs),
                      Text(
                        'Это вы',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              if (onMessageTap != null) ...[
                _AclMessageButton(onTap: onMessageTap!),
                const SizedBox(width: PawlySpacing.xs),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _memberName(AclMemberProfile? profile) {
    final firstName = profile?.firstName?.trim() ?? '';
    final lastName = profile?.lastName?.trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final displayName = profile?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    return 'Участник';
  }
}

class _AclMessageButton extends StatelessWidget {
  const _AclMessageButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.pill),
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.64),
          ),
        ),
        child: Icon(
          Icons.chat_bubble_outline_rounded,
          size: 19,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

Future<void> _openDirectChat({
  required BuildContext context,
  required ProviderContainer ref,
  required String petId,
  required String otherUserId,
}) async {
  try {
    final conversation =
        await ref.read(chatRepositoryProvider).openConversation(
              OpenDirectChatInput(petId: petId, otherUserId: otherUserId),
            );
    if (!context.mounted) {
      return;
    }
    context.pushNamed(
      'chatConversation',
      pathParameters: <String, String>{
        'conversationId': conversation.conversationId,
      },
    );
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Не удалось открыть чат.')));
  }
}

class _AclInviteTile extends StatelessWidget {
  const _AclInviteTile({required this.invite, required this.onTap});

  final AclInvite invite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.xl),
      child: Ink(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.48,
                  ),
                  borderRadius: BorderRadius.circular(PawlyRadius.lg),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.64),
                  ),
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  size: 22,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: PawlySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _localizedRoleTitle(invite.role),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xxs),
                    Text(
                      'Код: ${invite.code}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AclAvatar extends StatelessWidget {
  const _AclAvatar({
    required this.userId,
    required this.photoUrl,
    required this.fallbackLabel,
    required this.showCrown,
  });

  final String userId;
  final String? photoUrl;
  final String fallbackLabel;
  final bool showCrown;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final resolvedPhotoUrl = hasPhoto ? _normalizeStorageUrl(photoUrl!) : null;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.62,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.64),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? PawlyCachedImage(
                    imageUrl: resolvedPhotoUrl!,
                    cacheKey: pawlyStableImageCacheKey(
                      scope: 'acl-avatar',
                      entityId: userId,
                      imageUrl: resolvedPhotoUrl,
                    ),
                    targetLogicalSize: 56,
                    fit: BoxFit.cover,
                    errorWidget: (_) =>
                        _AclAvatarFallback(label: fallbackLabel),
                  )
                : _AclAvatarFallback(label: fallbackLabel),
          ),
          if (showCrown)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(PawlyRadius.pill),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                  ),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _normalizeStorageUrl(String url) {
    final uri = Uri.tryParse(url);
    final apiUri = Uri.tryParse(ApiConstants.baseUrl);
    if (uri == null || apiUri == null || uri.host != 'minio') {
      return url;
    }

    return uri.replace(host: apiUri.host).toString();
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

class _AclAvatarFallback extends StatelessWidget {
  const _AclAvatarFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = label.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);

    return Center(
      child: Text(
        letter.toUpperCase(),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AclAccessErrorView extends StatelessWidget {
  const _AclAccessErrorView({required this.onRetry});

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
                  'Не удалось загрузить доступ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Проверьте соединение или попробуйте снова чуть позже.',
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
