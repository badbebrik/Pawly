import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationState =
        ref.watch(chatConversationControllerProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(
        title: conversationState.when(
          data: (state) => _ConversationAppBarTitle(state: state),
          loading: () => const Text('Чат'),
          error: (_, __) => const Text('Чат'),
        ),
      ),
      body: conversationState.when(
        data: (state) {
          _scheduleMarkRead(state);
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
                    padding: const EdgeInsets.fromLTRB(
                      PawlySpacing.lg,
                      PawlySpacing.md,
                      PawlySpacing.lg,
                      PawlySpacing.md,
                    ),
                    children: <Widget>[
                      if (state.hasMoreMessages)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: PawlySpacing.md,
                            ),
                            child: PawlyButton(
                              label: state.isLoadingMoreMessages
                                  ? 'Загружаем...'
                                  : 'Загрузить предыдущие',
                              onPressed: state.isLoadingMoreMessages
                                  ? null
                                  : () => ref
                                      .read(chatConversationControllerProvider(
                                              widget.conversationId)
                                          .notifier)
                                      .loadOlderMessages(),
                              variant: PawlyButtonVariant.secondary,
                              icon: Icons.expand_less_rounded,
                              fullWidth: false,
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
        .read(chatConversationControllerProvider(widget.conversationId).notifier)
        .sendMessage(text);
    _messageController.clear();
  }

  void _scheduleMarkRead(ChatConversationState state) {
    if (!state.canMarkRead || state.isMarkingRead) {
      return;
    }

    final lastMessageId = state.lastMessageId;
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
              child: Text(
                _dateFormat.format(messageDay),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
              Text(
                'По питомцу ${state.conversation.pet.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({
    required this.name,
    required this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _ConversationAvatarFallback(
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
    return Padding(
      padding: const EdgeInsets.only(top: PawlySpacing.xl),
      child: Center(
        child: Text(
          'Сообщений пока нет.',
          style: Theme.of(context).textTheme.bodyLarge,
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
          PawlySpacing.sm,
          PawlySpacing.md,
          PawlySpacing.md,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(color: colorScheme.outlineVariant),
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
                  hintText: canSend
                      ? 'Напишите сообщение'
                      : 'Отправка недоступна',
                ),
                onSubmitted: canSend && !isSending ? (_) => onSend() : null,
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            FilledButton(
              onPressed: canSend && !isSending ? onSend : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(52, 52),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PawlyRadius.lg),
                ),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_upward_rounded),
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
  });

  final String text;
  final String timeLabel;
  final bool isMine;
  final bool isSending;
  final bool hasFailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment:
          isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isMine
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(PawlyRadius.lg),
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
                  Text(text),
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
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          Text(
                            timeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: hasFailed
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
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
                        color: hasFailed
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
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
