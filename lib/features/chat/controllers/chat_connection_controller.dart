import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_socket_models.dart';
import '../states/chat_connection_state.dart';
import 'chat_dependencies.dart';

final chatSocketConnectionControllerProvider = AsyncNotifierProvider
    .autoDispose<ChatSocketConnectionController, ChatSocketConnectionState>(
  ChatSocketConnectionController.new,
);

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

    ref.onDispose(() {
      unawaited(lifecycleSubscription.cancel().catchError((_) {}));
    });

    return ChatSocketConnectionState(
      status: service.isConnected
          ? ChatSocketLifecycleStatus.connected
          : ChatSocketLifecycleStatus.error,
      reconnectAttempt: 0,
      errorMessage: service.isConnected ? null : 'WebSocket connection failed',
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
    try {
      await service.ensureConnected();
    } catch (_) {}
  }
}
