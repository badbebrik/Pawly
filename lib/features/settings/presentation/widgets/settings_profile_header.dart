import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/settings_profile.dart';
import '../../shared/formatters/settings_profile_formatters.dart';
import '../../shared/utils/settings_storage_url.dart';

class SettingsProfileHeader extends StatelessWidget {
  const SettingsProfileHeader({
    required this.profile,
    required this.isUploadingPhoto,
    required this.onAvatarTap,
    super.key,
  })  : title = null,
        subtitle = null,
        trailing = null;

  factory SettingsProfileHeader.loading() {
    return SettingsProfileHeader._placeholder(
      title: 'Загрузка профиля',
      subtitle: 'Получаем данные из профиля',
      trailing: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  factory SettingsProfileHeader.error({required VoidCallback onRetry}) {
    return SettingsProfileHeader._placeholder(
      title: 'Профиль недоступен',
      subtitle: 'Не удалось загрузить данные пользователя',
      trailing: TextButton(onPressed: onRetry, child: const Text('Повторить')),
    );
  }

  const SettingsProfileHeader._placeholder({
    required this.title,
    required this.subtitle,
    this.trailing,
  })  : profile = null,
        isUploadingPhoto = false,
        onAvatarTap = null,
        super(key: null);

  final SettingsProfile? profile;
  final bool isUploadingPhoto;
  final VoidCallback? onAvatarTap;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedProfile = profile;
    final resolvedTitle = resolvedProfile == null
        ? title ?? 'Профиль Pawly'
        : settingsProfileFullName(
            resolvedProfile.firstName,
            resolvedProfile.lastName,
          );
    final resolvedSubtitle = subtitle;
    final initials = resolvedProfile == null
        ? 'P'
        : settingsProfileInitials(
            resolvedProfile.firstName,
            resolvedProfile.lastName,
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PawlySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.64),
        ),
      ),
      child: Row(
        children: <Widget>[
          Stack(
            children: <Widget>[
              GestureDetector(
                onTap: onAvatarTap,
                child: _SettingsProfileAvatar(
                  userId: resolvedProfile?.userId,
                  photoUrl: resolvedProfile?.avatarDownloadUrl,
                  initials: initials,
                ),
              ),
              if (resolvedProfile != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              if (isUploadingPhoto)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: PawlySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  resolvedTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (resolvedSubtitle != null &&
                    resolvedSubtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: PawlySpacing.xxxs),
                  Text(
                    resolvedSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: PawlySpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _SettingsProfileAvatar extends StatelessWidget {
  const _SettingsProfileAvatar({
    required this.userId,
    required this.photoUrl,
    required this.initials,
  }) : size = 76;

  final String? userId;
  final String? photoUrl;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final resolvedPhotoUrl =
        hasPhoto ? normalizeSettingsStorageUrl(photoUrl!) : null;
    final resolvedUserId = userId;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
        color: colorScheme.primaryContainer,
      ),
      child: ClipOval(
        child: hasPhoto
            ? PawlyCachedImage(
                imageUrl: resolvedPhotoUrl!,
                cacheKey: resolvedUserId == null
                    ? null
                    : pawlyStableImageCacheKey(
                        scope: 'profile-avatar',
                        entityId: resolvedUserId,
                        imageUrl: resolvedPhotoUrl,
                      ),
                targetLogicalSize: size,
                fit: BoxFit.cover,
                errorWidget: (_) => _SettingsProfileAvatarFallback(
                  initials: initials,
                ),
              )
            : _SettingsProfileAvatarFallback(initials: initials),
      ),
    );
  }
}

class _SettingsProfileAvatarFallback extends StatelessWidget {
  const _SettingsProfileAvatarFallback({
    required this.initials,
  });

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
