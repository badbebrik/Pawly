import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/models/acl_models.dart';
import '../../../../design_system/design_system.dart';
import '../models/acl_screen_models.dart';
import '../providers/acl_controllers.dart';

class AclAccessPage extends ConsumerWidget {
  const AclAccessPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(aclAccessControllerProvider(petId));

    return Scaffold(
      appBar: AppBar(title: const Text('Совместный доступ')),
      body: accessState.when(
        data: (state) => _AclAccessContent(
          state: state,
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
    required this.onInviteTap,
    this.onCreateInvite,
  });

  final AclAccessScreenState state;
  final VoidCallback? onCreateInvite;
  final ValueChanged<String> onInviteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = state.membersForDisplay;
    final invites = state.activeInvites;

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Участники',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${members.length}',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: PawlySpacing.md),
        if (members.isEmpty)
          const Text('У этого питомца пока нет участников.')
        else
          ...members.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: PawlySpacing.md),
                child: _AclMemberTile(
                  member: member,
                  meUserId: state.me.userId,
                ),
              )),
        const SizedBox(height: PawlySpacing.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Активные приглашения',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${invites.length}',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: PawlySpacing.md),
        if (invites.isEmpty)
          const Text('Активных приглашений пока нет.')
        else
          ...invites.map((invite) => Padding(
                padding: const EdgeInsets.only(bottom: PawlySpacing.md),
                child: _AclInviteTile(
                  invite: invite,
                  onTap: () => onInviteTap(invite.id),
                ),
              )),
        if (onCreateInvite != null) ...<Widget>[
          const SizedBox(height: PawlySpacing.sm),
          PawlyButton(
            label: 'Создать приглашение',
            onPressed: onCreateInvite,
            icon: Icons.person_add_alt_1_rounded,
          ),
        ],
      ],
    );
  }
}

class _AclMemberTile extends StatelessWidget {
  const _AclMemberTile({
    required this.member,
    required this.meUserId,
  });

  final AclMember member;
  final String meUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMe = member.userId == meUserId;
    final profile = member.profile;
    final fullName = _memberName(profile);

    return PawlyCard(
      padding: const EdgeInsets.all(PawlySpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _AclAvatar(
            photoUrl: profile?.avatarDownloadUrl,
            fallbackLabel: fullName,
            showCrown: member.isPrimaryOwner,
          ),
          const SizedBox(width: PawlySpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Wrap(
                  spacing: PawlySpacing.xs,
                  runSpacing: PawlySpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    if (member.isPrimaryOwner)
                      const PawlyBadge(
                        label: 'Владелец',
                        tone: PawlyBadgeTone.warning,
                      ),
                    if (!member.isPrimaryOwner)
                      PawlyBadge(
                        label: _localizedRoleTitle(member.role),
                        tone: PawlyBadgeTone.neutral,
                      ),
                    if (isMe)
                      Text(
                        'Вы',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class _AclInviteTile extends StatelessWidget {
  const _AclInviteTile({
    required this.invite,
    required this.onTap,
  });

  final AclInvite invite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PawlyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(PawlySpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(PawlyRadius.md),
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: PawlySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _localizedRoleTitle(invite.role),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xxs),
                Text(
                  'Код: ${invite.code}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _AclAvatar extends StatelessWidget {
  const _AclAvatar({
    required this.photoUrl,
    required this.fallbackLabel,
    required this.showCrown,
  });

  final String? photoUrl;
  final String fallbackLabel;
  final bool showCrown;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final resolvedPhotoUrl = hasPhoto ? _normalizeStorageUrl(photoUrl!) : null;

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? CachedNetworkImage(
                    imageUrl: resolvedPhotoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _AclAvatarFallback(label: fallbackLabel),
                  )
                : _AclAvatarFallback(label: fallbackLabel),
          ),
          if (showCrown)
            Positioned(
              top: -4,
              right: -2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(PawlyRadius.pill),
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: Colors.black87,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить доступ'),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: const Text(
            'Проверьте соединение или попробуйте снова чуть позже.',
          ),
        ),
      ),
    );
  }
}
