import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_socket_models.dart';
import '../models/chat_models.dart';
import '../shared/mappers/chat_mappers.dart';
import '../states/chat_inbox_state.dart';
import 'chat_connection_controller.dart';
import 'chat_dependencies.dart';

final chatInboxControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ChatInboxController, ChatInboxState, String?>(
  ChatInboxController.new,
);

class ChatInboxController extends AsyncNotifier<ChatInboxState> {
  ChatInboxController(this._petIdFilter);

  final String? _petIdFilter;

  @override
  Future<ChatInboxState> build() async {
    ref.read(chatSocketConnectionControllerProvider);
    final service = ref.read(chatSocketServiceProvider);
    final subscription = service.events.listen((event) {
      if (event is! ConversationUpdatedEvent) {
        return;
      }

      final item = chatListItemFromNetwork(event.conversation);
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

      return item.copyWith(
        lastReadMessageId: lastReadMessageId,
        unreadCount: 0,
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
