import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../shared/utils/chat_storage_url.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.size,
    super.key,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final rawAvatarUrl = avatarUrl;
    final resolvedAvatarUrl = rawAvatarUrl == null || rawAvatarUrl.isEmpty
        ? null
        : normalizeChatStorageUrl(rawAvatarUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: resolvedAvatarUrl == null
          ? _ChatAvatarFallback(displayName: displayName, size: size)
          : PawlyCachedImage(
              imageUrl: resolvedAvatarUrl,
              cacheKey: pawlyStableImageCacheKey(
                scope: 'chat-avatar',
                entityId: userId,
                imageUrl: resolvedAvatarUrl,
              ),
              targetLogicalSize: size,
              fit: BoxFit.cover,
              errorWidget: (_) => _ChatAvatarFallback(
                displayName: displayName,
                size: size,
              ),
            ),
    );
  }
}

class _ChatAvatarFallback extends StatelessWidget {
  const _ChatAvatarFallback({
    required this.displayName,
    required this.size,
  });

  final String displayName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = displayName.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    final textStyle = size >= 52
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.titleMedium;

    return Center(
      child: Text(
        letter.toUpperCase(),
        style: textStyle?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
