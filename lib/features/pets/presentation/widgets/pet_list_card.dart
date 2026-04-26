import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/pet_list_entry.dart';
import '../../shared/formatters/pet_access_formatters.dart';
import '../../shared/formatters/pet_date_formatters.dart';
import '../../shared/widgets/pet_avatar_fallback.dart';
import '../../shared/widgets/pet_avatar_url.dart';

class PetListCard extends StatelessWidget {
  const PetListCard({
    required this.entry,
    this.onTap,
    this.onRestore,
    super.key,
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
                                'с ${petShortDateLabel(entry.pet.archivedAt!)}',
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
      petRoleCaption(entry.roleTitle),
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
        hasPhoto ? normalizePetStorageUrl(photoUrl!) : null;

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
                errorWidget: (_) => PetAvatarFallback(
                  colorScheme: colorScheme,
                  iconSize: 34,
                ),
              )
            : PetAvatarFallback(colorScheme: colorScheme, iconSize: 34),
      ),
    );
  }
}
