import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../design_system/design_system.dart';

class AclAvatar extends StatelessWidget {
  const AclAvatar({
    required this.userId,
    required this.photoUrl,
    required this.fallbackLabel,
    required this.showCrown,
    super.key,
  });

  final String userId;
  final String? photoUrl;
  final String fallbackLabel;
  final bool showCrown;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final resolvedPhotoUrl = hasPhoto ? _normalizeStorageUrl(photoUrl!) : null;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: _size,
            height: _size,
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
                    targetLogicalSize: _size,
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

String _normalizeStorageUrl(String url) {
  final uri = Uri.tryParse(url);
  final apiUri = Uri.tryParse(ApiConstants.baseUrl);
  if (uri == null || apiUri == null || uri.host != 'minio') {
    return url;
  }

  return uri.replace(host: apiUri.host).toString();
}
