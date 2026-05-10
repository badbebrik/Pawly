import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_dependencies.dart';
import '../data/chat_repository.dart';
import '../data/chat_socket_models.dart';
import '../models/chat_models.dart';
import '../shared/mappers/chat_mappers.dart';
import '../shared/utils/chat_client_message_id.dart';
import '../states/chat_conversation_state.dart';
import 'chat_connection_controller.dart';
import 'chat_dependencies.dart';
import 'chat_inbox_controller.dart';
import 'chat_unread_controller.dart';

const _ackTimeout = Duration(seconds: 12);
const _ackReconnectDebounce = Duration(seconds: 15);
const _reconnectReloadDebounce = Duration(seconds: 2);

final chatConversationControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ChatConversationController, ChatConversationState, String>(
  ChatConversationController.new,
);

class ChatConversationController extends AsyncNotifier<ChatConversationState> {
  ChatConversationController(this._conversationId);

  final String _conversationId;
  final Map<String, Timer> _pendingAckTimers = <String, Timer>{};
  bool _disposed = false;
  bool _ackReconnectInFlight = false;
  bool _reconnectReloadInFlight = false;
  DateTime? _lastAckReconnectAt;
  DateTime? _lastReconnectReloadAt;

  @override
  Future<ChatConversationState> build() async {
    _disposed = false;
    ref.read(chatSocketConnectionControllerProvider);
    final service = ref.read(chatSocketServiceProvider);
    final repository = ref.read(chatRepositoryProvider);

    final subscription = service.events.listen((event) {
      switch (event) {
        case MessageAckEvent():
          _handleMessageAck(event);
        case MessageNewEvent():
          _handleMessageNew(event);
        case ReadUpdatedEvent():
          _handleReadUpdated(event);
        case ConversationUpdatedEvent():
          if (event.conversation.conversationId == _conversationId) {
            _patchConversation(chatListItemFromNetwork(event.conversation));
          }
        case ConversationPresenceUpdatedEvent():
          _handleConversationPresenceUpdated(event);
        default:
          break;
      }
    });
    final lifecycleSubscription = service.lifecycleEvents.listen((event) {
      if (event.status != ChatSocketLifecycleStatus.connected) {
        return;
      }
      unawaited(_reloadAfterReconnect(repository));
    });

    ref.onDispose(() {
      _disposed = true;
      for (final timer in _pendingAckTimers.values) {
        timer.cancel();
      }
      _pendingAckTimers.clear();
      unawaited(subscription.cancel().catchError((_) {}));
      unawaited(lifecycleSubscription.cancel().catchError((_) {}));
      unawaited(
        service.unsubscribeConversation(_conversationId).catchError((_) {}),
      );
    });

    Future<void>(() async {
      try {
        await service.subscribeConversation(_conversationId);
      } catch (_) {}
    });

    return _loadInitialState(repository);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    try {
      state =
          AsyncData(await _loadInitialState(ref.read(chatRepositoryProvider)));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> loadOlderMessages() async {
    final current = state.asData?.value;
    if (current == null ||
        current.isLoadingMoreMessages ||
        !current.hasMoreMessages ||
        current.messages.isEmpty) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMoreMessages: true));

    try {
      final page = await ref.read(chatRepositoryProvider).getMessages(
            _conversationId,
            beforeMessageId: current.messages.first.messageId,
          );

      final merged = <ChatMessageItem>[
        ...page.messages.reversed,
        ...current.messages,
      ];

      state = AsyncData(
        current.copyWith(
          messages: merged,
          hasMoreMessages: page.hasMore,
          isLoadingMoreMessages: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> markReadUpTo(String lastReadMessageId) async {
    final current = state.asData?.value;
    if (current == null ||
        current.isMarkingRead ||
        lastReadMessageId.isEmpty ||
        current.conversation.lastReadMessageId == lastReadMessageId) {
      return;
    }

    state = AsyncData(current.copyWith(isMarkingRead: true));
    final hadUnread = current.conversation.unreadCount > 0;
    final unreadMessages = current.conversation.unreadCount;
    _applyLocalReadState(
      current: current,
      lastReadMessageId: lastReadMessageId,
    );

    try {
      try {
        await ref.read(chatSocketServiceProvider).markRead(
              conversationId: _conversationId,
              lastReadMessageId: lastReadMessageId,
            );
      } catch (_) {
        await ref.read(chatRepositoryProvider).markRead(
              MarkChatReadInput(
                conversationId: _conversationId,
                lastReadMessageId: lastReadMessageId,
              ),
            );
      }
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }
      _rollbackLocalReadState(
        current: current,
        hadUnread: hadUnread,
        unreadMessages: unreadMessages,
      );
      state = AsyncError(error, stackTrace);
    } finally {
      final latest = _disposed ? null : state.asData?.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(isMarkingRead: false));
      }
    }
  }

  Future<void> sendMessage(String text) async {
    final current = state.asData?.value;
    final normalizedText = text.trim();
    if (current == null ||
        current.isSendingMessage ||
        normalizedText.isEmpty ||
        !current.conversation.canSend) {
      return;
    }

    final clientMessageId = generateChatClientMessageId();
    final optimisticMessage = ChatMessageItem(
      messageId: '$chatLocalMessageIdPrefix$clientMessageId',
      conversationId: _conversationId,
      senderUserId: current.currentUserId,
      clientMessageId: clientMessageId,
      text: normalizedText,
      createdAt: DateTime.now().toUtc(),
      deliveryStatus: ChatMessageDeliveryStatus.sending,
    );

    state = AsyncData(
      current.copyWith(
        messages: <ChatMessageItem>[
          ...current.messages,
          optimisticMessage,
        ],
        isSendingMessage: true,
        conversation: _mergeConversationWithMessage(
          current.conversation,
          optimisticMessage,
          unreadCount: 0,
        ),
      ),
    );

    try {
      await ref.read(chatSocketServiceProvider).sendMessage(
            conversationId: _conversationId,
            clientMessageId: clientMessageId,
            text: normalizedText,
          );
      if (_disposed) {
        return;
      }
      _scheduleAckTimeout(clientMessageId);
      final latest = state.asData?.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(isSendingMessage: false));
      }
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }
      _clearAckTimeout(clientMessageId);
      final latest = state.asData?.value ?? current;
      state = AsyncError(error, stackTrace);
      state = AsyncData(
        latest.copyWith(
          isSendingMessage: false,
          messages: latest.messages.map((message) {
            if (message.clientMessageId != clientMessageId) {
              return message;
            }
            return message.copyWith(
              deliveryStatus: ChatMessageDeliveryStatus.failed,
            );
          }).toList(growable: false),
        ),
      );
    }
  }

  void _patchConversation(ChatListItem value) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(conversation: value));
  }

  void _handleMessageAck(MessageAckEvent event) {
    if (event.message.conversationId != _conversationId) {
      return;
    }

    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final ackMessage = chatMessageItemFromNetwork(event.message);
    _clearAckTimeout(ackMessage.clientMessageId);
    final nextMessages = current.messages.map((message) {
      if (message.clientMessageId != ackMessage.clientMessageId) {
        return message;
      }
      return ackMessage;
    }).toList(growable: false);

    state = AsyncData(
      current.copyWith(
        messages: _dedupeMessages(nextMessages),
        isSendingMessage: false,
        conversation: _mergeConversationWithMessage(
          current.conversation,
          ackMessage,
          unreadCount: 0,
        ),
      ),
    );
  }

  void _handleMessageNew(MessageNewEvent event) {
    if (event.message.conversationId != _conversationId) {
      return;
    }

    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final newMessage = chatMessageItemFromNetwork(event.message);
    _clearAckTimeout(newMessage.clientMessageId);
    final hasByMessageId = current.messages.any(
      (message) => message.messageId == newMessage.messageId,
    );
    if (hasByMessageId) {
      return;
    }

    final nextMessages = <ChatMessageItem>[
      ...current.messages.where((message) {
        return message.clientMessageId == null ||
            newMessage.clientMessageId == null ||
            message.clientMessageId != newMessage.clientMessageId;
      }),
      newMessage,
    ];

    final isMine = newMessage.senderUserId == current.currentUserId;
    state = AsyncData(
      current.copyWith(
        messages: _dedupeMessages(nextMessages),
        conversation: _mergeConversationWithMessage(
          current.conversation,
          newMessage,
          unreadCount: isMine ? 0 : current.conversation.unreadCount,
        ),
      ),
    );
  }

  void _handleReadUpdated(ReadUpdatedEvent event) {
    if (event.conversationId != _conversationId) {
      return;
    }

    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        conversation: current.conversation.copyWith(
          lastReadMessageId: event.userId == current.currentUserId
              ? event.lastReadMessageId
              : current.conversation.lastReadMessageId,
          otherUserLastReadMessageId: event.userId == current.currentUserId
              ? current.conversation.otherUserLastReadMessageId
              : event.lastReadMessageId,
          unreadCount: event.userId == current.currentUserId
              ? 0
              : current.conversation.unreadCount,
        ),
      ),
    );

    if (event.userId == current.currentUserId) {
      ref.read(chatInboxControllerProvider(null).notifier).markConversationRead(
            conversationId: _conversationId,
            lastReadMessageId: event.lastReadMessageId,
          );
      ref
          .read(chatInboxControllerProvider(current.conversation.pet.petId)
              .notifier)
          .markConversationRead(
            conversationId: _conversationId,
            lastReadMessageId: event.lastReadMessageId,
          );
    }
  }

  void _handleConversationPresenceUpdated(
    ConversationPresenceUpdatedEvent event,
  ) {
    if (event.conversationId != _conversationId) {
      return;
    }

    final current = state.asData?.value;
    if (current == null || event.userId == current.currentUserId) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        conversation: current.conversation.copyWith(
          otherUserInChat: event.isInChat,
        ),
      ),
    );
  }

  ChatListItem _mergeConversationWithMessage(
    ChatListItem conversation,
    ChatMessageItem message, {
    required int unreadCount,
  }) {
    return conversation.copyWith(
      lastMessageId: message.messageId,
      lastMessageAt: message.createdAt,
      lastMessagePreview: message.text,
      lastMessageSenderId: message.senderUserId,
      unreadCount: unreadCount,
    );
  }

  List<ChatMessageItem> _dedupeMessages(List<ChatMessageItem> messages) {
    final byMessageId = <String>{};
    final byClientId = <String>{};
    final result = <ChatMessageItem>[];

    for (final message in messages) {
      final messageId = message.messageId;
      final clientId = message.clientMessageId;
      if (messageId.isNotEmpty && byMessageId.contains(messageId)) {
        continue;
      }
      if (clientId != null &&
          clientId.isNotEmpty &&
          byClientId.contains(clientId)) {
        continue;
      }

      if (messageId.isNotEmpty) {
        byMessageId.add(messageId);
      }
      if (clientId != null && clientId.isNotEmpty) {
        byClientId.add(clientId);
      }
      result.add(message);
    }

    result.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });

    return result;
  }

  void _scheduleAckTimeout(String clientMessageId) {
    _clearAckTimeout(clientMessageId);
    _pendingAckTimers[clientMessageId] = Timer(
      _ackTimeout,
      () {
        if (_disposed) {
          return;
        }
        _pendingAckTimers.remove(clientMessageId);
        final current = state.asData?.value;
        if (current == null) {
          return;
        }

        var changed = false;
        final nextMessages = current.messages.map((message) {
          if (message.clientMessageId != clientMessageId ||
              !message.isSending) {
            return message;
          }
          changed = true;
          return message.copyWith(
            deliveryStatus: ChatMessageDeliveryStatus.failed,
          );
        }).toList(growable: false);

        if (!changed) {
          return;
        }
        unawaited(_reconnectAfterAckTimeout());

        state = AsyncData(
          current.copyWith(
            messages: nextMessages,
            isSendingMessage: false,
          ),
        );
      },
    );
  }

  void _clearAckTimeout(String? clientMessageId) {
    if (clientMessageId == null || clientMessageId.isEmpty) {
      return;
    }
    _pendingAckTimers.remove(clientMessageId)?.cancel();
  }

  Future<void> _reconnectAfterAckTimeout() async {
    if (_disposed || _ackReconnectInFlight) {
      return;
    }

    final now = DateTime.now();
    final lastReconnectAt = _lastAckReconnectAt;
    if (lastReconnectAt != null &&
        now.difference(lastReconnectAt) < _ackReconnectDebounce) {
      return;
    }

    _ackReconnectInFlight = true;
    _lastAckReconnectAt = now;
    try {
      await ref.read(chatSocketServiceProvider).reconnect();
    } catch (_) {
    } finally {
      _ackReconnectInFlight = false;
    }
  }

  Future<void> _reloadAfterReconnect(ChatRepository repository) async {
    if (_disposed || _reconnectReloadInFlight) {
      return;
    }

    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final now = DateTime.now();
    final lastReloadAt = _lastReconnectReloadAt;
    if (lastReloadAt != null &&
        now.difference(lastReloadAt) < _reconnectReloadDebounce) {
      return;
    }
    _lastReconnectReloadAt = now;
    _reconnectReloadInFlight = true;

    try {
      final reloaded = await _loadInitialState(repository);
      if (_disposed) {
        return;
      }
      final latest = state.asData?.value;
      if (latest == null) {
        return;
      }

      state = AsyncData(_mergeReloadedState(latest, reloaded));
    } catch (_) {
    } finally {
      _reconnectReloadInFlight = false;
    }
  }

  ChatConversationState _mergeReloadedState(
    ChatConversationState current,
    ChatConversationState reloaded,
  ) {
    final serverClientIds = reloaded.messages
        .map((message) => message.clientMessageId)
        .whereType<String>()
        .where((clientId) => clientId.isNotEmpty)
        .toSet();
    final localUnresolved = current.messages.where((message) {
      final clientId = message.clientMessageId;
      if (clientId == null || clientId.isEmpty) {
        return false;
      }
      if (!message.isSending && !message.hasFailed) {
        return false;
      }
      return !serverClientIds.contains(clientId);
    });
    final mergedMessages = _dedupeMessages(
      <ChatMessageItem>[
        ...reloaded.messages,
        ...localUnresolved,
      ],
    );

    return reloaded.copyWith(
      messages: mergedMessages,
      isSendingMessage: mergedMessages.any((message) => message.isSending),
    );
  }

  Future<ChatConversationState> _loadInitialState(
    ChatRepository repository,
  ) async {
    final currentUserIdFuture = ref.read(currentUserIdProvider.future);
    final conversationFuture = repository.getConversation(_conversationId);
    final messagesPageFuture = repository.getMessages(_conversationId);

    final currentUserId = await currentUserIdFuture;
    final conversation = await conversationFuture;
    final messagesPage = await messagesPageFuture;

    return ChatConversationState(
      currentUserId: currentUserId ?? '',
      conversation: conversation,
      messages: messagesPage.messages.reversed.toList(growable: false),
      hasMoreMessages: messagesPage.hasMore,
      isLoadingMoreMessages: false,
      isMarkingRead: false,
      isSendingMessage: false,
    );
  }

  void _applyLocalReadState({
    required ChatConversationState current,
    required String lastReadMessageId,
  }) {
    final hadUnread = current.conversation.unreadCount > 0;
    final unreadMessages = current.conversation.unreadCount;

    state = AsyncData(
      current.copyWith(
        conversation: current.conversation.copyWith(
          lastReadMessageId: lastReadMessageId,
          unreadCount: 0,
        ),
        isMarkingRead: true,
      ),
    );

    ref.read(chatInboxControllerProvider(null).notifier).markConversationRead(
          conversationId: _conversationId,
          lastReadMessageId: lastReadMessageId,
        );
    ref
        .read(chatInboxControllerProvider(current.conversation.pet.petId)
            .notifier)
        .markConversationRead(
          conversationId: _conversationId,
          lastReadMessageId: lastReadMessageId,
        );

    if (hadUnread) {
      ref.read(chatUnreadSummaryControllerProvider.notifier).decrement(
            unreadConversationsDelta: 1,
            unreadMessagesDelta: unreadMessages,
          );
    }
  }

  void _rollbackLocalReadState({
    required ChatConversationState current,
    required bool hadUnread,
    required int unreadMessages,
  }) {
    state = AsyncData(current.copyWith(isMarkingRead: false));
    ref.read(chatInboxControllerProvider(null).notifier).upsertConversation(
          current.conversation,
        );
    ref
        .read(chatInboxControllerProvider(current.conversation.pet.petId)
            .notifier)
        .upsertConversation(
          current.conversation,
        );

    if (hadUnread) {
      final unreadController = ref.read(
        chatUnreadSummaryControllerProvider.notifier,
      );
      final unreadState = unreadController.state.asData?.value ??
          const ChatUnreadSummary(
            unreadConversations: 0,
            unreadMessages: 0,
          );
      unreadController.patch(
        ChatUnreadSummary(
          unreadConversations: unreadState.unreadConversations + 1,
          unreadMessages: unreadState.unreadMessages + unreadMessages,
        ),
      );
    }
  }
}
