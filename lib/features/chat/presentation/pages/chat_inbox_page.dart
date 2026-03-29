import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../design_system/design_system.dart';
import '../../data/chat_repository_models.dart';
import '../providers/chat_providers.dart';

class ChatInboxPage extends ConsumerStatefulWidget {
  const ChatInboxPage({super.key});

  @override
  ConsumerState<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends ConsumerState<ChatInboxPage> {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('d MMM', 'ru');

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(chatInboxControllerProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сообщения'),
      ),
      body: inboxState.when(
        data: (state) => RefreshIndicator(
          onRefresh: _refresh,
          child: state.items.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(PawlySpacing.lg),
                  children: const <Widget>[
                    SizedBox(height: PawlySpacing.xxl),
                    _EmptyInboxState(),
                  ],
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(PawlySpacing.lg),
                  itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: PawlySpacing.md),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: PawlySpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final item = state.items[index];
                    return _InboxConversationTile(
                      item: item,
                      onTap: () => context.pushNamed(
                        'chatConversation',
                        pathParameters: <String, String>{
                          'conversationId': item.conversationId,
                        },
                      ),
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: PawlyCard(
              title: const Text('Не удалось загрузить чаты'),
              footer: PawlyButton(
                label: 'Повторить',
                onPressed: _refresh,
                variant: PawlyButtonVariant.secondary,
              ),
              child: const Text(
                'Попробуйте обновить экран или вернуться позже.',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    await Future.wait<void>(<Future<void>>[
      ref.read(chatInboxControllerProvider(null).notifier).reload(),
      ref.read(chatUnreadSummaryControllerProvider.notifier).reload(),
    ]);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240) {
      return;
    }

    ref.read(chatInboxControllerProvider(null).notifier).loadMore();
  }
}

class _InboxConversationTile extends StatelessWidget {
  const _InboxConversationTile({
    required this.item,
    required this.onTap,
  });

  final ChatListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedAvatarUrl = item.peer.avatarUrl == null ||
            item.peer.avatarUrl!.isEmpty
        ? null
        : _normalizeStorageUrl(item.peer.avatarUrl!);
    final preview = item.lastMessagePreview?.trim();
    final timeLabel = _formatTimestamp(item.lastMessageAt?.toLocal());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: item.hasUnread
                ? colorScheme.primaryContainer.withValues(alpha: 0.42)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _InboxAvatar(
                  displayName: item.peer.displayName,
                  avatarUrl: resolvedAvatarUrl,
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
                      const SizedBox(height: PawlySpacing.xs),
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
                      const SizedBox(height: PawlySpacing.sm),
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

  String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return '';
    }

    final now = DateTime.now();
    final sameDay =
        now.year == value.year && now.month == value.month && now.day == value.day;

    return sameDay ? _ChatInboxPageState._timeFormat.format(value) : _ChatInboxPageState._dateFormat.format(value);
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
        horizontal: PawlySpacing.sm,
        vertical: PawlySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InboxAvatar extends StatelessWidget {
  const _InboxAvatar({
    required this.displayName,
    required this.avatarUrl,
  });

  final String displayName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  _InboxAvatarFallback(displayName: displayName),
            )
          : _InboxAvatarFallback(displayName: displayName),
    );
  }
}

class _InboxAvatarFallback extends StatelessWidget {
  const _InboxAvatarFallback({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final trimmed = displayName.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);

    return Center(
      child: Text(
        letter.toUpperCase(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
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
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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

class _EmptyInboxState extends StatelessWidget {
  const _EmptyInboxState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: PawlySpacing.md),
          Text(
            'У вас пока нет чатов',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            'Откройте диалог из списка участников питомца.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
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
