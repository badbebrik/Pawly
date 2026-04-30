import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_socket_models.dart';
import '../models/chat_models.dart';
import '../shared/mappers/chat_mappers.dart';
import 'chat_connection_controller.dart';
import 'chat_dependencies.dart';

final chatUnreadSummaryControllerProvider = AsyncNotifierProvider.autoDispose<
    ChatUnreadSummaryController, ChatUnreadSummary>(
  ChatUnreadSummaryController.new,
);

class ChatUnreadSummaryController extends AsyncNotifier<ChatUnreadSummary> {
  @override
  Future<ChatUnreadSummary> build() async {
    ref.read(chatSocketConnectionControllerProvider);
    final service = ref.read(chatSocketServiceProvider);

    final subscription = service.events.listen((event) {
      if (event is! GlobalUnreadUpdatedEvent) {
        return;
      }

      patch(chatUnreadSummaryFromNetwork(event.summary));
    });
    ref.onDispose(subscription.cancel);

    return ref.read(chatRepositoryProvider).getUnreadSummary();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state =
        AsyncData(await ref.read(chatRepositoryProvider).getUnreadSummary());
  }

  void patch(ChatUnreadSummary value) {
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
      ChatUnreadSummary(
        unreadConversations:
            (current.unreadConversations - unreadConversationsDelta)
                .clamp(0, 1 << 31),
        unreadMessages:
            (current.unreadMessages - unreadMessagesDelta).clamp(0, 1 << 31),
      ),
    );
  }
}
