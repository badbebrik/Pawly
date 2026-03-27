import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/chat_repository.dart';
import '../../data/chat_repository_models.dart';
import '../models/chat_screen_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final chatApiClient = ref.watch(chatApiClientProvider);
  return ChatRepository(chatApiClient: chatApiClient);
});

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

class ChatUnreadSummaryController extends AsyncNotifier<ChatUnreadState> {
  @override
  Future<ChatUnreadState> build() async {
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
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      ref.read(currentUserIdProvider.future),
      ref.read(chatRepositoryProvider).getConversation(_conversationId),
      ref.read(chatRepositoryProvider).getMessages(_conversationId),
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

  void patchConversation(ChatListItem value) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(conversation: value));
  }
}
