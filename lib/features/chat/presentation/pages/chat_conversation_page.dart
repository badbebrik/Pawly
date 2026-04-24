import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../design_system/design_system.dart';
import '../models/chat_screen_models.dart';
import '../providers/chat_providers.dart';

class ChatConversationPage extends ConsumerStatefulWidget {
  const ChatConversationPage({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  ConsumerState<ChatConversationPage> createState() =>
      _ChatConversationPageState();
}

class _ChatConversationPageState extends ConsumerState<ChatConversationPage> {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('d MMMM', 'ru');
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sendErrorShown = false;
  String? _lastTailMessageKey;
  bool _initialScrollDone = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationState =
        ref.watch(chatConversationControllerProvider(widget.conversationId));

    return PawlyScreenScaffold(
      titleWidget: conversationState.when(
        data: (state) => _ConversationAppBarTitle(state: state),
        loading: () => const Text('Чат'),
        error: (_, __) => const Text('Чат'),
      ),
      body: conversationState.when(
        data: (state) {
          _scheduleSendErrorToast(state);
          _scheduleMarkRead(state);
          _scheduleAutoScroll(state);
          return Column(
            children: <Widget>[
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .read(chatConversationControllerProvider(
                              widget.conversationId)
                          .notifier)
                      .reload(),
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      PawlySpacing.md,
                      PawlySpacing.md,
                      PawlySpacing.md,
                      PawlySpacing.md,
                    ),
                    children: <Widget>[
                      if (state.hasMoreMessages)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: PawlySpacing.md,
                            ),
                            child: _LoadOlderButton(
                              isLoading: state.isLoadingMoreMessages,
                              onPressed: state.isLoadingMoreMessages
                                  ? null
                                  : () => ref
                                      .read(chatConversationControllerProvider(
                                              widget.conversationId)
                                          .notifier)
                                      .loadOlderMessages(),
                            ),
                          ),
                        ),
                      if (state.messages.isEmpty)
                        const _EmptyConversationState()
                      else
                        ..._buildMessageGroups(context, state),
                    ],
                  ),
                ),
              ),
              _ConversationComposer(
                controller: _messageController,
                canSend: state.conversation.canSend,
                isSending: state.isSendingMessage,
                onSend: _handleSend,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: PawlyCard(
              title: const Text('Не удалось загрузить чат'),
              footer: PawlyButton(
                label: 'Повторить',
                onPressed: () => ref
                    .read(chatConversationControllerProvider(
                            widget.conversationId)
                        .notifier)
                    .reload(),
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

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    ref
        .read(
            chatConversationControllerProvider(widget.conversationId).notifier)
        .sendMessage(text);
    _messageController.clear();
  }

  void _scheduleMarkRead(ChatConversationState state) {
    if (!state.canMarkRead || state.isMarkingRead) {
      return;
    }

    final lastMessageId = state.lastReadableMessageId;
    if (lastMessageId == null || lastMessageId.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(chatConversationControllerProvider(widget.conversationId)
              .notifier)
          .markReadUpTo(lastMessageId);
    });
  }

  void _scheduleSendErrorToast(ChatConversationState state) {
    final hasFailed = state.messages.any((message) => message.hasFailed);
    if (!hasFailed) {
      _sendErrorShown = false;
      return;
    }
    if (_sendErrorShown) {
      return;
    }

    _sendErrorShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Не удалось отправить сообщение. Проверьте соединение.'),
        ),
      );
    });
  }

  void _scheduleAutoScroll(ChatConversationState state) {
    if (state.messages.isEmpty) {
      _lastTailMessageKey = null;
      return;
    }

    final tail = state.messages.last;
    final tailKey = '${tail.messageId}|${tail.clientMessageId}|'
        '${tail.deliveryStatus.name}|${state.messages.length}';
    final shouldInitialScroll = !_initialScrollDone;
    final shouldScrollToNewTail = _lastTailMessageKey != tailKey;

    _lastTailMessageKey = tailKey;

    if (!shouldInitialScroll && !shouldScrollToNewTail) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final targetOffset = _scrollController.position.maxScrollExtent;
      if (shouldInitialScroll) {
        _initialScrollDone = true;
        _scrollController.jumpTo(targetOffset);
        return;
      }

      await _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  List<Widget> _buildMessageGroups(
    BuildContext context,
    ChatConversationState state,
  ) {
    final List<Widget> widgets = <Widget>[];
    DateTime? previousDay;

    for (final message in state.messages) {
      final createdAt = message.createdAt?.toLocal();
      final messageDay = createdAt == null
          ? null
          : DateTime(createdAt.year, createdAt.month, createdAt.day);

      if (messageDay != null && previousDay != messageDay) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PawlySpacing.md),
            child: Center(
              child: _DateSeparator(
                label: _dateFormat.format(messageDay),
              ),
            ),
          ),
        );
        previousDay = messageDay;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
          child: _MessageBubble(
            text: message.text,
            timeLabel: createdAt == null ? '' : _timeFormat.format(createdAt),
            isMine: message.senderUserId == state.currentUserId,
            isSending: message.isSending,
            hasFailed: message.hasFailed,
            isReadByPeer: state.isMessageReadByPeer(message.messageId),
          ),
        ),
      );
    }

    return widgets;
  }
}

class _ConversationAppBarTitle extends StatelessWidget {
  const _ConversationAppBarTitle({required this.state});

  final ChatConversationState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = state.conversation.peer.avatarUrl;
    final resolvedAvatarUrl = avatarUrl == null || avatarUrl.isEmpty
        ? null
        : _normalizeStorageUrl(avatarUrl);

    return Row(
      children: <Widget>[
        _ConversationAvatar(
          userId: state.conversation.peer.userId,
          name: state.conversation.peer.displayName,
          avatarUrl: resolvedAvatarUrl,
        ),
        const SizedBox(width: PawlySpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                state.conversation.peer.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: state.conversation.otherUserInChat
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: PawlySpacing.xxs),
                  Expanded(
                    child: Text(
                      '${state.conversation.otherUserInChat ? 'В чате' : 'Не в чате'} · ${state.conversation.pet.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.sm,
        vertical: PawlySpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _LoadOlderButton extends StatelessWidget {
  const _LoadOlderButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
        foregroundColor: colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.md,
          vertical: PawlySpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.pill),
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
      label: Text(
        isLoading ? 'Загружаем' : 'Ранее',
        style: theme.textTheme.labelLarge,
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.userId,
    required this.name,
    required this.avatarUrl,
  });

  final String userId;
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? PawlyCachedImage(
              imageUrl: avatarUrl!,
              cacheKey: pawlyStableImageCacheKey(
                scope: 'chat-avatar',
                entityId: userId,
                imageUrl: avatarUrl!,
              ),
              targetLogicalSize: 38,
              fit: BoxFit.cover,
              errorWidget: (_) => _ConversationAvatarFallback(
                name: name,
              ),
            )
          : _ConversationAvatarFallback(name: name),
    );
  }
}

class _ConversationAvatarFallback extends StatelessWidget {
  const _ConversationAvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);

    return Center(
      child: Text(
        letter.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _EmptyConversationState extends StatelessWidget {
  const _EmptyConversationState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: PawlySpacing.xl),
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            PawlySpacing.lg,
            PawlySpacing.lg,
            PawlySpacing.lg,
            PawlySpacing.lg,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
          ),
          child: Text(
            'Сообщений пока нет',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationComposer extends StatelessWidget {
  const _ConversationComposer({
    required this.controller,
    required this.canSend,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.xs,
          PawlySpacing.md,
          PawlySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: pawlyGroupedBackground(context),
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                enabled: canSend,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      canSend ? 'Напишите сообщение' : 'Отправка недоступна',
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: PawlySpacing.md,
                    vertical: PawlySpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PawlyRadius.xl),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PawlyRadius.xl),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PawlyRadius.xl),
                    borderSide: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.28),
                    ),
                  ),
                ),
                onSubmitted: canSend && !isSending ? (_) => onSend() : null,
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: canSend && !isSending ? onSend : null,
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor:
                      colorScheme.onSurface.withValues(alpha: 0.08),
                  foregroundColor: colorScheme.onPrimary,
                  disabledForegroundColor: colorScheme.onSurfaceVariant,
                ),
                icon: isSending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.timeLabel,
    required this.isMine,
    required this.isSending,
    required this.hasFailed,
    required this.isReadByPeer,
  });

  final String text;
  final String timeLabel;
  final bool isMine;
  final bool isSending;
  final bool hasFailed;
  final bool isReadByPeer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bubbleColor = isMine ? colorScheme.primary : colorScheme.surface;
    final foreground = isMine ? colorScheme.onPrimary : colorScheme.onSurface;
    final metaColor = isMine
        ? colorScheme.onPrimary.withValues(alpha: 0.78)
        : colorScheme.onSurfaceVariant;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.76;

    return Row(
      mainAxisAlignment:
          isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(PawlyRadius.xl),
                topRight: const Radius.circular(PawlyRadius.xl),
                bottomLeft: Radius.circular(
                  isMine ? PawlyRadius.xl : PawlyRadius.sm,
                ),
                bottomRight: Radius.circular(
                  isMine ? PawlyRadius.sm : PawlyRadius.xl,
                ),
              ),
              boxShadow: isMine
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                PawlySpacing.md,
                PawlySpacing.sm,
                PawlySpacing.md,
                PawlySpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      height: 1.32,
                    ),
                  ),
                  if (timeLabel.isNotEmpty) ...<Widget>[
                    const SizedBox(height: PawlySpacing.xs),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (hasFailed)
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: PawlySpacing.xs),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 14,
                                color: colorScheme.error,
                              ),
                            ),
                          if (isSending)
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: PawlySpacing.xs),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: metaColor,
                                ),
                              ),
                            ),
                          Text(
                            timeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: hasFailed ? colorScheme.error : metaColor,
                            ),
                          ),
                          if (isMine && !hasFailed && !isSending) ...<Widget>[
                            const SizedBox(width: PawlySpacing.xs),
                            Icon(
                              isReadByPeer
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 14,
                              color: isReadByPeer
                                  ? (isMine
                                      ? colorScheme.onPrimary
                                      : colorScheme.primary)
                                  : metaColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else if (isSending || hasFailed) ...<Widget>[
                    const SizedBox(height: PawlySpacing.xs),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(
                        hasFailed
                            ? Icons.error_outline_rounded
                            : Icons.schedule_rounded,
                        size: 14,
                        color: hasFailed ? colorScheme.error : metaColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
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
