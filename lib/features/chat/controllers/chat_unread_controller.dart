import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_models.dart';
import 'chat_dependencies.dart';

const _unreadPollingInterval = Duration(seconds: 30);

final chatUnreadSummaryControllerProvider = AsyncNotifierProvider.autoDispose<
    ChatUnreadSummaryController, ChatUnreadSummary>(
  ChatUnreadSummaryController.new,
);

class ChatUnreadSummaryController extends AsyncNotifier<ChatUnreadSummary> {
  Timer? _pollTimer;
  bool _disposed = false;
  bool _reloadInFlight = false;

  @override
  Future<ChatUnreadSummary> build() async {
    _disposed = false;
    _pollTimer = Timer.periodic(_unreadPollingInterval, (_) {
      unawaited(_reloadSilently());
    });

    ref.onDispose(() {
      _disposed = true;
      _pollTimer?.cancel();
      _pollTimer = null;
    });

    return ref.read(chatRepositoryProvider).getUnreadSummary();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state =
        AsyncData(await ref.read(chatRepositoryProvider).getUnreadSummary());
  }

  Future<void> _reloadSilently() async {
    if (_disposed || _reloadInFlight) {
      return;
    }

    _reloadInFlight = true;
    try {
      patch(await ref.read(chatRepositoryProvider).getUnreadSummary());
    } catch (_) {
    } finally {
      _reloadInFlight = false;
    }
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
