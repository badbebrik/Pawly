import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/chat_models.dart';
import '../../shared/formatters/chat_date_formatters.dart';
import 'chat_avatar.dart';

class ChatConversationTile extends StatelessWidget {
  const ChatConversationTile({
    required this.item,
    required this.onTap,
    super.key,
  });

  final ChatListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final preview = item.lastMessagePreview?.trim();
    final timeLabel = chatInboxTimestampLabel(item.lastMessageAt);
    final borderRadius = BorderRadius.circular(PawlyRadius.xl);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: item.hasUnread
                ? colorScheme.primary.withValues(alpha: 0.20)
                : colorScheme.outlineVariant.withValues(alpha: 0.82),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PawlySpacing.md,
              vertical: PawlySpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ChatAvatar(
                  userId: item.peer.userId,
                  displayName: item.peer.displayName,
                  avatarUrl: item.peer.avatarUrl,
                  size: 60,
                ),
                const SizedBox(width: PawlySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.peer.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: item.hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: PawlySpacing.sm),
                          Text(
                            timeLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: item.hasUnread
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: item.hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: PawlySpacing.xxs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              preview == null || preview.isEmpty
                                  ? 'Начните диалог'
                                  : preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: item.hasUnread
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: item.hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (item.hasUnread) ...<Widget>[
                            const SizedBox(width: PawlySpacing.sm),
                            _UnreadBadge(count: item.unreadCount),
                          ],
                        ],
                      ),
                      const SizedBox(height: PawlySpacing.xs),
                      _PetPill(name: item.pet.name),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetPill extends StatelessWidget {
  const _PetPill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.xs,
        vertical: PawlySpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(PawlyRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.pets_rounded,
            size: 13,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: PawlySpacing.xxs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
