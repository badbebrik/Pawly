import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

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
  final service = ChatSocketService(authSessionStore: authSessionStore);
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
      final current =
          state.asData?.value ?? const ChatSocketConnectionState.disconnected();
      state = AsyncData(current.copyWith(lastEventType: event.type));
    });

    ref.onDispose(() async {
      await lifecycleSubscription.cancel();
      await eventSubscription.cancel();
    });

    await service.ensureConnected();
    await service.subscribeInbox();

    return const ChatSocketConnectionState(
      status: ChatSocketLifecycleStatus.connected,
      reconnectAttempt: 0,
    );
  }

  Future<void> reconnect() async {
    state = AsyncData(
      (state.asData?.value ?? const ChatSocketConnectionState.disconnected())
          .copyWith(
        status: ChatSocketLifecycleStatus.connecting,
        clearErrorMessage: true,
      ),
    );

    final service = ref.read(chatSocketServiceProvider);
    await service.disconnect();
    await service.ensureConnected();
    await service.subscribeInbox();
  }
}

class ChatUnreadSummaryController extends AsyncNotifier<ChatUnreadState> {
  @override
  Future<ChatUnreadState> build() async {
    ref.watch(chatSocketConnectionControllerProvider);
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
}

class ChatInboxController extends AsyncNotifier<ChatInboxState> {
  ChatInboxController(this._petIdFilter);

  final String? _petIdFilter;

  @override
  Future<ChatInboxState> build() async {
    ref.watch(chatSocketConnectionControllerProvider);
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

  @override
  Future<ChatConversationState> build() async {
    ref.watch(chatSocketConnectionControllerProvider);
    final service = ref.read(chatSocketServiceProvider);
    final repository = ref.read(chatRepositoryProvider);

    final subscription = service.events.listen((event) {
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
        default:
          break;
      }
    });

    ref.onDispose(() async {
      await subscription.cancel();
      await service.unsubscribeConversation(_conversationId);
    });

    await service.subscribeConversation(_conversationId);

    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      ref.read(currentUserIdProvider.future),
      repository.getConversation(_conversationId),
      repository.getMessages(_conversationId),
    ]);

    final currentUserId = results[0] as String?;
    final conversation = results[1] as ChatListItem;
    final messagesPage = results[2] as ChatMessagePageData;

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

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
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

    try {
      await ref.read(chatRepositoryProvider).markRead(
            MarkChatReadInput(
              conversationId: _conversationId,
              lastReadMessageId: lastReadMessageId,
            ),
          );

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
            unreadCount: 0,
            canSend: current.conversation.canSend,
          ),
          isMarkingRead: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
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

    final clientMessageId = _generateClientMessageId();
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
      final latest = state.asData?.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(isSendingMessage: false));
      }
    } catch (error, stackTrace) {
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

    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final ackMessage = repository.mapMessage(event.message);
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

    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final newMessage = repository.mapMessage(event.message);
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
        conversation: ChatListItem(
          conversationId: current.conversation.conversationId,
          pet: current.conversation.pet,
          peer: current.conversation.peer,
          lastMessageId: current.conversation.lastMessageId,
          lastMessageAt: current.conversation.lastMessageAt,
          lastMessagePreview: current.conversation.lastMessagePreview,
          lastMessageSenderId: current.conversation.lastMessageSenderId,
          lastReadMessageId: event.lastReadMessageId,
          unreadCount: event.userId == current.currentUserId
              ? 0
              : current.conversation.unreadCount,
          canSend: current.conversation.canSend,
        ),
      ),
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
      unreadCount: unreadCount,
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
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(1 << 32).toRadixString(16);
    return 'msg-$timestamp-$suffix';
  }
}
