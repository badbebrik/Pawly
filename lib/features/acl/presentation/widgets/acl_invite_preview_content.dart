import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../pets/shared/widgets/pet_avatar_url.dart';
import '../../models/acl_invite_preview.dart';
import '../../shared/formatters/acl_invite_formatters.dart';
import '../../shared/widgets/acl_form_section.dart';
import '../../shared/widgets/acl_read_only_permissions_list.dart';
import '../../states/acl_invite_preview_state.dart';

class AclInvitePreviewContent extends StatelessWidget {
  const AclInvitePreviewContent({
    required this.state,
    required this.onAccept,
    required this.onClose,
    super.key,
  });

  final AclInvitePreviewState state;
  final Future<void> Function() onAccept;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final preview = state.preview;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        _InvitePetHeaderCard(
          pet: preview.pet,
          roleTitle: preview.roleTitle,
        ),
        const SizedBox(height: PawlySpacing.md),
        AclFormSection(
          title: 'Доступ',
          child: Column(
            children: <Widget>[
              _InviteMetaRow(label: 'Роль', value: preview.roleTitle),
              const Divider(height: PawlySpacing.lg),
              _InviteMetaRow(label: 'Код', value: preview.code),
              if (preview.expiresAt != null) ...<Widget>[
                const Divider(height: PawlySpacing.lg),
                _InviteMetaRow(
                  label: 'Срок действия',
                  value: aclInviteExpiryLabel(preview.expiresAt!),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        AclFormSection(
          title: 'Права доступа',
          child: AclReadOnlyPermissionsList(draft: preview.permissions),
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

  final AclInvitePet pet;
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
              petId: pet.id,
              photoUrl: pet.photoUrl,
              name: pet.name,
            ),
            const SizedBox(width: PawlySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pet.displayName,
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

class _InvitePetAvatar extends StatelessWidget {
  const _InvitePetAvatar({
    required this.petId,
    required this.photoUrl,
    required this.name,
  });

  final String petId;
  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final resolvedPhotoUrl =
        hasPhoto ? normalizePetStorageUrl(photoUrl!) : null;
    final initial = name.trim().isEmpty ? 'P' : name.trim().characters.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(PawlyRadius.lg),
      child: Container(
        width: 68,
        height: 68,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        child: !hasPhoto
            ? _InvitePetInitial(initial: initial)
            : PawlyCachedImage(
                imageUrl: resolvedPhotoUrl!,
                cacheKey: pawlyStableImageCacheKey(
                  scope: 'pet-avatar',
                  entityId: petId,
                  imageUrl: resolvedPhotoUrl,
                ),
                targetLogicalSize: 68,
                fit: BoxFit.cover,
                errorWidget: (_) => _InvitePetInitial(initial: initial),
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
