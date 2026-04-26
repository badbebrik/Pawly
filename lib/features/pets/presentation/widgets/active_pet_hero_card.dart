import 'package:flutter/material.dart';

import '../../../../core/network/models/pet_models.dart';
import '../../../../design_system/design_system.dart';
import '../../shared/widgets/pet_avatar_fallback.dart';
import '../../shared/widgets/pet_avatar_url.dart';

class ActivePetHeroCard extends StatelessWidget {
  const ActivePetHeroCard({
    required this.pet,
    required this.speciesName,
    required this.ageLabel,
    required this.isUploadingPhoto,
    this.onPhotoTap,
    this.onEdit,
    required this.onMore,
    super.key,
  });

  final Pet pet;
  final String speciesName;
  final String ageLabel;
  final bool isUploadingPhoto;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onEdit;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _HeroPetAvatar(
              petId: pet.id,
              photoFileId: pet.profilePhotoFileId,
              photoUrl: pet.profilePhotoDownloadUrl,
              isUploadingPhoto: isUploadingPhoto,
              onTap: onPhotoTap,
            ),
            const SizedBox(width: PawlySpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: PawlySpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xs),
                    Text(
                      '$speciesName · $ageLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _HeroCompactActionButton(
                  onPressed: onEdit,
                  icon: Icons.edit_rounded,
                  tooltip: 'Редактировать питомца',
                ),
                const SizedBox(height: PawlySpacing.xs),
                _HeroCompactActionButton(
                  onPressed: onMore,
                  icon: Icons.more_horiz_rounded,
                  tooltip: 'Действия',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPetAvatar extends StatelessWidget {
  const _HeroPetAvatar({
    required this.petId,
    required this.photoFileId,
    required this.photoUrl,
    required this.isUploadingPhoto,
    this.onTap,
  });

  final String petId;
  final String? photoFileId;
  final String? photoUrl;
  final bool isUploadingPhoto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final resolvedPhotoUrl =
        hasPhoto ? normalizePetStorageUrl(photoUrl!) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface,
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (hasPhoto)
                PawlyCachedImage(
                  imageUrl: resolvedPhotoUrl!,
                  cacheKey: pawlyStableImageCacheKey(
                    scope: 'pet-avatar',
                    entityId: photoFileId ?? petId,
                    imageUrl: resolvedPhotoUrl,
                  ),
                  targetLogicalSize: 108,
                  fit: BoxFit.cover,
                  errorWidget: (_) =>
                      PetAvatarFallback(colorScheme: colorScheme),
                )
              else
                PetAvatarFallback(colorScheme: colorScheme),
              if (isUploadingPhoto)
                Container(
                  color: Colors.black.withValues(alpha: 0.30),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCompactActionButton extends StatelessWidget {
  const _HeroCompactActionButton({
    this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 38,
        height: 38,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurfaceVariant,
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          iconSize: 18,
          icon: Icon(icon),
        ),
      ),
    );
  }
}
