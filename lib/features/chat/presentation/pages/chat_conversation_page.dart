import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/chat_conversation_controller.dart';
import '../../states/chat_conversation_state.dart';
import '../widgets/chat_conversation_header.dart';
import '../widgets/chat_message_composer.dart';
import '../widgets/chat_message_list.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sendErrorShown = false;
  String? _lastTailMessageKey;
  String? _pendingMarkReadMessageId;
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
        data: (state) => ChatConversationHeader(state: state),
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
                  onRefresh: _reload,
                  child: ChatMessageList(
                    state: state,
                    scrollController: _scrollController,
                    onLoadOlder: _loadOlderMessages,
                  ),
                ),
              ),
              ChatMessageComposer(
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
                onPressed: () => unawaited(_reload()),
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

  Future<void> _reload() async {
    try {
      await ref
          .read(chatConversationControllerProvider(widget.conversationId)
              .notifier)
          .reload();
    } catch (_) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: 'Не удалось загрузить чат. Попробуйте еще раз.',
        tone: PawlySnackBarTone.error,
      );
    }
  }

  void _loadOlderMessages() {
    ref
        .read(
            chatConversationControllerProvider(widget.conversationId).notifier)
        .loadOlderMessages();
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
      _pendingMarkReadMessageId = null;
      return;
    }

    final lastMessageId = state.lastReadableMessageId;
    if (lastMessageId == null || lastMessageId.isEmpty) {
      return;
    }
    if (state.conversation.lastReadMessageId == lastMessageId ||
        _pendingMarkReadMessageId == lastMessageId) {
      return;
    }

    _pendingMarkReadMessageId = lastMessageId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        if (_pendingMarkReadMessageId == lastMessageId) {
          _pendingMarkReadMessageId = null;
        }
        return;
      }

      try {
        final latest = ref
            .read(chatConversationControllerProvider(widget.conversationId))
            .asData
            ?.value;
        if (latest?.conversation.lastReadMessageId == lastMessageId) {
          return;
        }
        await ref
            .read(chatConversationControllerProvider(widget.conversationId)
                .notifier)
            .markReadUpTo(lastMessageId);
      } catch (_) {
        // Mark-read is best-effort; it must not create an unhandled
        // post-frame exception loop.
      } finally {
        if (_pendingMarkReadMessageId == lastMessageId) {
          _pendingMarkReadMessageId = null;
        }
      }
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
      showPawlySnackBar(
        context,
        message: 'Не удалось отправить сообщение. Проверьте соединение.',
        tone: PawlySnackBarTone.error,
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

      try {
        final targetOffset = _scrollController.position.maxScrollExtent;
        if (shouldInitialScroll) {
          _initialScrollDone = true;
          _scrollController.jumpTo(targetOffset);
          return;
        }

        if (!mounted || !_scrollController.hasClients) {
          return;
        }

        await _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    });
  }
}
