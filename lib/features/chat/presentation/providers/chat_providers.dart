import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/chat_repository.dart';
import '../../data/chat_repository_models.dart';
import '../../data/chat_socket_models.dart';
import '../../data/chat_socket_service.dart';
import '../models/chat_screen_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final chatApiClient = ref.watch(chatApiClientProvider);
  return ChatRepository(chatApiClient: chatApiClient);
});

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final authSessionStore = ref.watch(authSessionStoreProvider);
  final service = ChatSocketService(
    authSessionStore: authSessionStore,
  );
  ref.onDispose(service.dispose);
  return service;
});

final chatSocketConnectionControllerProvider = AsyncNotifierProvider<
    ChatSocketConnectionController, ChatSocketConnectionState>(
  ChatSocketConnectionController.new,
);

final chatUnreadSummaryControllerProvider = AsyncNotifierProvider.autoDispose<
    ChatUnreadSummaryController, ChatUnreadState>(
  ChatUnreadSummaryController.new,
);

final chatInboxControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ChatInboxController, ChatInboxState, String?>(
  ChatInboxController.new,
);

final chatConversationControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ChatConversationController, ChatConversationState, String>(
  ChatConversationController.new,
);

class ChatSocketConnectionState {
  const ChatSocketConnectionState({
    required this.status,
    required this.reconnectAttempt,
    this.lastEventType,
    this.errorMessage,
  });

  const ChatSocketConnectionState.disconnected()
      : status = ChatSocketLifecycleStatus.disconnected,
        reconnectAttempt = 0,
        lastEventType = null,
        errorMessage = null;

  final ChatSocketLifecycleStatus status;
  final int reconnectAttempt;
  final String? lastEventType;
  final String? errorMessage;

  bool get isConnected => status == ChatSocketLifecycleStatus.connected;

  ChatSocketConnectionState copyWith({
    ChatSocketLifecycleStatus? status,
    int? reconnectAttempt,
    String? lastEventType,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ChatSocketConnectionState(
      status: status ?? this.status,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      lastEventType: lastEventType ?? this.lastEventType,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChatSocketConnectionController
    extends AsyncNotifier<ChatSocketConnectionState> {
  @override
  Future<ChatSocketConnectionState> build() async {
    final service = ref.read(chatSocketServiceProvider);

    final lifecycleSubscription = service.lifecycleEvents.listen((event) {
      _chatConnectionLog(
        'lifecycle status=${event.status.name} '
        'attempt=${event.reconnectAttempt} error=${event.errorMessage}',
      );
      final current =
          state.asData?.value ?? const ChatSocketConnectionState.disconnected();
      state = AsyncData(
        current.copyWith(
          status: event.status,
          reconnectAttempt: event.reconnectAttempt,
          errorMessage: event.errorMessage,
          clearErrorMessage: event.errorMessage == null,
        ),
      );
    });

    final eventSubscription = service.events.listen((event) {
      _chatConnectionLog('event type=${event.type}');
      final current =
          state.asData?.value ?? const ChatSocketConnectionState.disconnected();
      state = AsyncData(current.copyWith(lastEventType: event.type));
    });

    ref.onDispose(() async {
      await lifecycleSubscription.cancel();
      await eventSubscription.cancel();
    });

    try {
      _chatConnectionLog('build: ensureConnected');
      await service.ensureConnected();
      if (service.isConnected) {
        _chatConnectionLog('build: subscribeInbox');
        await service.subscribeInbox();
      }
    } catch (error) {
      _chatConnectionLog('build: connection failed error=$error');
    }

    return ChatSocketConnectionState(
      status: service.isConnected
          ? ChatSocketLifecycleStatus.connected
          : ChatSocketLifecycleStatus.error,
      reconnectAttempt: 0,
      errorMessage: service.isConnected ? null : 'WebSocket connection failed',
    );
  }

  Future<void> reconnect() async {
    _chatConnectionLog('reconnect: manual reconnect requested');
    state = AsyncData(
      (state.asData?.value ?? const ChatSocketConnectionState.disconnected())
          .copyWith(
        status: ChatSocketLifecycleStatus.connecting,
        clearErrorMessage: true,
      ),
    );

    final service = ref.read(chatSocketServiceProvider);
    await service.disconnect();
    try {
      await service.ensureConnected();
      if (service.isConnected) {
        await service.subscribeInbox();
      }
    } catch (error) {
      _chatConnectionLog('reconnect: failed error=$error');
      // lifecycle state already updated by the socket service
    }
  }
}

class ChatUnreadSummaryController extends AsyncNotifier<ChatUnreadState> {
  @override
  Future<ChatUnreadState> build() async {
    ref.read(chatSocketConnectionControllerProvider);
    final service = ref.read(chatSocketServiceProvider);

    final subscription = service.events.listen((event) {
      if (event is! GlobalUnreadUpdatedEvent) {
        return;
      }

      patch(
        ChatUnreadState(
          unreadConversations: event.summary.unreadConversations,
          unreadMessages: event.summary.unreadMessages,
        ),
      );
    });
    ref.onDispose(subscription.cancel);

    return ref.read(chatRepositoryProvider).getUnreadSummary();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state =
        AsyncData(await ref.read(chatRepositoryProvider).getUnreadSummary());
  }

  void patch(ChatUnreadState value) {
    state = AsyncData(value);
  }

  void decrement({
    required int unreadConversationsDelta,
    required int unreadMessagesDelta,
  }) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    patch(
      ChatUnreadState(
        unreadConversations:
            (current.unreadConversations - unreadConversationsDelta)
                .clamp(0, 1 << 31),
        unreadMessages:
            (current.unreadMessages - unreadMessagesDelta).clamp(0, 1 << 31),
      ),
    );
  }
}

class ChatInboxController extends AsyncNotifier<ChatInboxState> {
  ChatInboxController(this._petIdFilter);

  final String? _petIdFilter;

  @override
  Future<ChatInboxState> build() async {
    ref.read(chatSocketConnectionControllerProvider);
    final service = ref.read(chatSocketServiceProvider);
    final repository = ref.read(chatRepositoryProvider);

    final subscription = service.events.listen((event) {
      if (event is! ConversationUpdatedEvent) {
        return;
      }

      final item = repository.mapConversation(event.conversation);
      if (_petIdFilter != null &&
          _petIdFilter.isNotEmpty &&
          item.pet.petId != _petIdFilter) {
        return;
      }

      upsertConversation(item);
    });
    ref.onDispose(subscription.cancel);

    final base = ChatInboxState.initial(petIdFilter: _petIdFilter);
    return _loadInitial(base);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(
      await _loadInitial(ChatInboxState.initial(petIdFilter: _petIdFilter)),
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final page = await ref.read(chatRepositoryProvider).listConversations(
            petId: _petIdFilter,
            cursor: current.nextCursor,
          );

      final merged = <ChatListItem>[
        ...current.items,
        ...page.items.where((item) {
          return current.items.every(
            (existing) => existing.conversationId != item.conversationId,
          );
        }),
      ];

      state = AsyncData(
        current.copyWith(
          items: merged,
          nextCursor: page.nextCursor,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void upsertConversation(ChatListItem item) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final index = current.items.indexWhere(
      (existing) => existing.conversationId == item.conversationId,
    );

    final nextItems = <ChatListItem>[...current.items];
    if (index >= 0) {
      nextItems[index] = item;
    } else {
      nextItems.insert(0, item);
    }

    nextItems.sort((a, b) {
      final aTime = a.lastMessageAt;
      final bTime = b.lastMessageAt;
      if (aTime == null && bTime == null) {
        return 0;
      }
      if (aTime == null) {
        return 1;
      }
      if (bTime == null) {
        return -1;
      }
      return bTime.compareTo(aTime);
    });

    state = AsyncData(current.copyWith(items: nextItems));
  }

  void markConversationRead({
    required String conversationId,
    required String lastReadMessageId,
  }) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final nextItems = current.items.map((item) {
      if (item.conversationId != conversationId) {
        return item;
      }

      return ChatListItem(
        conversationId: item.conversationId,
        pet: item.pet,
        peer: item.peer,
        lastMessageId: item.lastMessageId,
        lastMessageAt: item.lastMessageAt,
        lastMessagePreview: item.lastMessagePreview,
        lastMessageSenderId: item.lastMessageSenderId,
        lastReadMessageId: lastReadMessageId,
        otherUserLastReadMessageId: item.otherUserLastReadMessageId,
        unreadCount: 0,
        otherUserInChat: item.otherUserInChat,
        canSend: item.canSend,
      );
    }).toList(growable: false);

    state = AsyncData(current.copyWith(items: nextItems));
  }

  Future<ChatInboxState> _loadInitial(ChatInboxState base) async {
    final page = await ref.read(chatRepositoryProvider).listConversations(
          petId: _petIdFilter,
        );

    return base.copyWith(
      items: page.items,
      nextCursor: page.nextCursor,
      isLoadingMore: false,
    );
  }
}

class ChatConversationController extends AsyncNotifier<ChatConversationState> {
  ChatConversationController(this._conversationId);

  final String _conversationId;
  final Map<String, Timer> _pendingAckTimers = <String, Timer>{};

  @override
  Future<ChatConversationState> build() async {
    _chatConversationLog(
      _conversationId,
      'build: initialize conversation controller',
    );
    ref.read(chatSocketConnectionControllerProvider);
    final service = ref.read(chatSocketServiceProvider);
    final repository = ref.read(chatRepositoryProvider);

    final subscription = service.events.listen((event) {
      _chatConversationLog(
        _conversationId,
        'event: type=${event.type}',
      );
      switch (event) {
        case MessageAckEvent():
          _handleMessageAck(repository, event);
        case MessageNewEvent():
          _handleMessageNew(repository, event);
        case ReadUpdatedEvent():
          _handleReadUpdated(event);
        case ConversationUpdatedEvent():
          if (event.conversation.conversationId == _conversationId) {
            patchConversation(repository.mapConversation(event.conversation));
          }
        case ConversationPresenceUpdatedEvent():
          _handleConversationPresenceUpdated(event);
        case ChatServerErrorEvent():
          _handleServerError(event);
        default:
          break;
      }
    });

    ref.onDispose(() async {
      for (final timer in _pendingAckTimers.values) {
        timer.cancel();
      }
      _pendingAckTimers.clear();
      await subscription.cancel();
      _chatConversationLog(
        _conversationId,
        'dispose: unsubscribe conversation',
      );
      await service.unsubscribeConversation(_conversationId);
    });

    Future<void>(() async {
      try {
        _chatConversationLog(
          _conversationId,
          'subscribe: request conversation subscription',
        );
        await service.subscribeConversation(_conversationId);
      } catch (error) {
        _chatConversationLog(
          _conversationId,
          'subscribe: failed error=$error',
        );
      }
    });

    return _loadInitialState(repository);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state =
        AsyncData(await _loadInitialState(ref.read(chatRepositoryProvider)));
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
      _chatConversationLog(
        _conversationId,
        'markRead: skipped currentNull=${current == null} '
        'isMarking=${current?.isMarkingRead} '
        'lastReadMessageId=$lastReadMessageId '
        'sameAsCurrent=${current?.conversation.lastReadMessageId == lastReadMessageId}',
      );
      return;
    }

    _chatConversationLog(
      _conversationId,
      'markRead: start lastReadMessageId=$lastReadMessageId '
      'unread=${current.conversation.unreadCount}',
    );
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
        _chatConversationLog(
          _conversationId,
          'markRead: sent via websocket',
        );
      } catch (error) {
        _chatConversationLog(
          _conversationId,
          'markRead: websocket failed, fallback to REST error=$error',
        );
        await ref.read(chatRepositoryProvider).markRead(
              MarkChatReadInput(
                conversationId: _conversationId,
                lastReadMessageId: lastReadMessageId,
              ),
            );
        _chatConversationLog(
          _conversationId,
          'markRead: sent via REST fallback',
        );
      }
    } catch (error, stackTrace) {
      _chatConversationLog(
        _conversationId,
        'markRead: failed error=$error',
      );
      _rollbackLocalReadState(
        current: current,
        hadUnread: hadUnread,
        unreadMessages: unreadMessages,
      );
      state = AsyncError(error, stackTrace);
    } finally {
      final latest = state.asData?.value;
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
      _chatConversationLog(
        _conversationId,
        'send: blocked currentNull=${current == null} '
        'isSending=${current?.isSendingMessage} '
        'isEmpty=${normalizedText.isEmpty} '
        'canSend=${current?.conversation.canSend}',
      );
      return;
    }

    final clientMessageId = _generateClientMessageId();
    _chatConversationLog(
      _conversationId,
      'send: start clientMessageId=$clientMessageId '
      'textLength=${normalizedText.length}',
    );
    final optimisticMessage = ChatMessageItem(
      messageId: 'local-$clientMessageId',
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
      _chatConversationLog(
        _conversationId,
        'send: websocket event sent clientMessageId=$clientMessageId',
      );
      _scheduleAckTimeout(clientMessageId);
      final latest = state.asData?.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(isSendingMessage: false));
      }
    } catch (error, stackTrace) {
      _chatConversationLog(
        _conversationId,
        'send: failed clientMessageId=$clientMessageId error=$error',
      );
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

  bool hasFailedMessages() {
    final current = state.asData?.value;
    if (current == null) {
      return false;
    }

    return current.messages.any((message) => message.hasFailed);
  }

  void patchConversation(ChatListItem value) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(conversation: value));
  }

  void _handleMessageAck(
    ChatRepository repository,
    MessageAckEvent event,
  ) {
    if (event.message.conversationId != _conversationId) {
      return;
    }
    _chatConversationLog(
      _conversationId,
      'ack: messageId=${event.message.messageId} '
      'clientMessageId=${event.message.clientMsgId}',
    );

    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final ackMessage = repository.mapMessage(event.message);
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

  void _handleMessageNew(
    ChatRepository repository,
    MessageNewEvent event,
  ) {
    if (event.message.conversationId != _conversationId) {
      return;
    }
    _chatConversationLog(
      _conversationId,
      'message_new: messageId=${event.message.messageId} '
      'clientMessageId=${event.message.clientMsgId} '
      'sender=${event.message.senderUserId}',
    );

    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final newMessage = repository.mapMessage(event.message);
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
    _chatConversationLog(
      _conversationId,
      'read_updated: userId=${event.userId} '
      'lastReadMessageId=${event.lastReadMessageId}',
    );

    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        conversation: ChatListItem(
          conversationId: current.conversation.conversationId,
          pet: current.conversation.pet,
          peer: current.conversation.peer,
          lastMessageId: current.conversation.lastMessageId,
          lastMessageAt: current.conversation.lastMessageAt,
          lastMessagePreview: current.conversation.lastMessagePreview,
          lastMessageSenderId: current.conversation.lastMessageSenderId,
          lastReadMessageId: event.userId == current.currentUserId
              ? event.lastReadMessageId
              : current.conversation.lastReadMessageId,
          otherUserLastReadMessageId: event.userId == current.currentUserId
              ? current.conversation.otherUserLastReadMessageId
              : event.lastReadMessageId,
          unreadCount: event.userId == current.currentUserId
              ? 0
              : current.conversation.unreadCount,
          otherUserInChat: current.conversation.otherUserInChat,
          canSend: current.conversation.canSend,
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
    _chatConversationLog(
      _conversationId,
      'presence: userId=${event.userId} isInChat=${event.isInChat}',
    );

    final current = state.asData?.value;
    if (current == null || event.userId == current.currentUserId) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        conversation: ChatListItem(
          conversationId: current.conversation.conversationId,
          pet: current.conversation.pet,
          peer: current.conversation.peer,
          lastMessageId: current.conversation.lastMessageId,
          lastMessageAt: current.conversation.lastMessageAt,
          lastMessagePreview: current.conversation.lastMessagePreview,
          lastMessageSenderId: current.conversation.lastMessageSenderId,
          lastReadMessageId: current.conversation.lastReadMessageId,
          otherUserLastReadMessageId:
              current.conversation.otherUserLastReadMessageId,
          unreadCount: current.conversation.unreadCount,
          otherUserInChat: event.isInChat,
          canSend: current.conversation.canSend,
        ),
      ),
    );
  }

  void _handleServerError(ChatServerErrorEvent event) {
    _chatConversationLog(
      _conversationId,
      'server_error: code=${event.code} message=${event.message}',
    );
  }

  ChatListItem _mergeConversationWithMessage(
    ChatListItem conversation,
    ChatMessageItem message, {
    required int unreadCount,
  }) {
    return ChatListItem(
      conversationId: conversation.conversationId,
      pet: conversation.pet,
      peer: conversation.peer,
      lastMessageId: message.messageId,
      lastMessageAt: message.createdAt,
      lastMessagePreview: message.text,
      lastMessageSenderId: message.senderUserId,
      lastReadMessageId: conversation.lastReadMessageId,
      otherUserLastReadMessageId: conversation.otherUserLastReadMessageId,
      unreadCount: unreadCount,
      otherUserInChat: conversation.otherUserInChat,
      canSend: conversation.canSend,
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

  String _generateClientMessageId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  void _scheduleAckTimeout(String clientMessageId) {
    _clearAckTimeout(clientMessageId);
    _chatConversationLog(
      _conversationId,
      'ack-timeout: scheduled clientMessageId=$clientMessageId timeout=12s',
    );
    _pendingAckTimers[clientMessageId] = Timer(
      const Duration(seconds: 12),
      () {
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
        _chatConversationLog(
          _conversationId,
          'ack-timeout: fired clientMessageId=$clientMessageId',
        );

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

  Future<ChatConversationState> _loadInitialState(
    ChatRepository repository,
  ) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      ref.read(currentUserIdProvider.future),
      repository.getConversation(_conversationId),
      repository.getMessages(_conversationId),
    ]);

    final currentUserId = results[0] as String?;
    final conversation = results[1] as ChatListItem;
    final messagesPage = results[2] as ChatMessagePageData;
    _chatConversationLog(
      _conversationId,
      'initial: currentUserId=${currentUserId ?? ''} '
      'canSend=${conversation.canSend} '
      'otherUserInChat=${conversation.otherUserInChat} '
      'messages=${messagesPage.messages.length} '
      'hasMore=${messagesPage.hasMore}',
    );

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
        conversation: ChatListItem(
          conversationId: current.conversation.conversationId,
          pet: current.conversation.pet,
          peer: current.conversation.peer,
          lastMessageId: current.conversation.lastMessageId,
          lastMessageAt: current.conversation.lastMessageAt,
          lastMessagePreview: current.conversation.lastMessagePreview,
          lastMessageSenderId: current.conversation.lastMessageSenderId,
          lastReadMessageId: lastReadMessageId,
          otherUserLastReadMessageId:
              current.conversation.otherUserLastReadMessageId,
          unreadCount: 0,
          otherUserInChat: current.conversation.otherUserInChat,
          canSend: current.conversation.canSend,
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
          const ChatUnreadState(
            unreadConversations: 0,
            unreadMessages: 0,
          );
      unreadController.patch(
        ChatUnreadState(
          unreadConversations: unreadState.unreadConversations + 1,
          unreadMessages: unreadState.unreadMessages + unreadMessages,
        ),
      );
    }
  }
}

void _chatConnectionLog(String message) {
  debugPrint('[chat/connection] $message');
}

void _chatConversationLog(String conversationId, String message) {
  debugPrint('[chat/conversation:$conversationId] $message');
}
