import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/acl_access.dart';
import '../../models/acl_member.dart';
import '../../shared/widgets/acl_avatar.dart';
import '../../shared/widgets/acl_message_button.dart';
import '../../states/acl_access_state.dart';

class AclAccessContent extends StatelessWidget {
  const AclAccessContent({
    required this.state,
    required this.onMemberTap,
    required this.onInviteTap,
    this.onMessageTap,
    this.onCreateInvite,
    super.key,
  });

  final AclAccessState state;
  final VoidCallback? onCreateInvite;
  final ValueChanged<String> onMemberTap;
  final ValueChanged<String> onInviteTap;
  final ValueChanged<String>? onMessageTap;

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
                onMessageTap:
                    member.userId == state.me.userId || onMessageTap == null
                        ? null
                        : () => onMessageTap!(member.userId),
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
    final fullName = member.displayName;

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
              AclAvatar(
                userId: member.userId,
                photoUrl: profile?.avatarUrl,
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
                          : 'Роль: ${member.roleTitle}',
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
                AclMessageButton(
                  onTap: onMessageTap!,
                  size: 38,
                  iconSize: 19,
                ),
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
}

class _AclInviteTile extends StatelessWidget {
  const _AclInviteTile({required this.invite, required this.onTap});

  final AclAccessInvite invite;
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
                      invite.roleTitle,
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
