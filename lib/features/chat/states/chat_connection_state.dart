import '../data/chat_socket_models.dart';

class ChatSocketConnectionState {
  const ChatSocketConnectionState({
    required this.status,
    required this.reconnectAttempt,
    this.errorMessage,
  });

  const ChatSocketConnectionState.disconnected()
      : status = ChatSocketLifecycleStatus.disconnected,
        reconnectAttempt = 0,
        errorMessage = null;

  final ChatSocketLifecycleStatus status;
  final int reconnectAttempt;
  final String? errorMessage;

  bool get isConnected => status == ChatSocketLifecycleStatus.connected;

  ChatSocketConnectionState copyWith({
    ChatSocketLifecycleStatus? status,
    int? reconnectAttempt,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ChatSocketConnectionState(
      status: status ?? this.status,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
