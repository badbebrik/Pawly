import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/session/auth_session_store.dart';
import 'chat_socket_models.dart';

class ChatSocketService {
  ChatSocketService({
    required AuthSessionStore authSessionStore,
  }) : _authSessionStore = authSessionStore;

  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _disconnectTimeout = Duration(seconds: 3);
  static const Duration _sendConnectionTimeout = Duration(seconds: 12);

  final AuthSessionStore _authSessionStore;

  final StreamController<ChatServerEvent> _eventsController =
      StreamController<ChatServerEvent>.broadcast();
  final StreamController<ChatSocketLifecycleEvent> _lifecycleController =
      StreamController<ChatSocketLifecycleEvent>.broadcast();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Future<void>? _connectFuture;
  Future<void>? _disconnectFuture;
  Timer? _reconnectTimer;

  bool _disposed = false;
  bool _disconnectRequested = false;
  int _inboxSubscriptionCount = 0;
  int _reconnectAttempt = 0;
  int _connectionGeneration = 0;
  final Map<String, int> _conversationSubscriptionCounts = <String, int>{};

  Stream<ChatServerEvent> get events => _eventsController.stream;
  Stream<ChatSocketLifecycleEvent> get lifecycleEvents =>
      _lifecycleController.stream;

  bool get isConnected =>
      _socket != null && _socket!.readyState == WebSocket.open;

  Future<void> ensureConnected() {
    if (_disposed) {
      return Future<void>.error(
        StateError('Chat socket service has been disposed.'),
      );
    }

    final pending = _connectFuture;
    if (pending != null) {
      return pending;
    }
    if (isConnected) {
      return Future<void>.value();
    }

    final disconnecting = _disconnectFuture;
    if (disconnecting != null) {
      return Future<void>.error(
        StateError('Chat socket is disconnecting.'),
      );
    }

    final generation = ++_connectionGeneration;
    _connectFuture = _connectInternal(generation);
    return _connectFuture!;
  }

  Future<void> disconnect() {
    final pending = _disconnectFuture;
    if (pending != null) {
      return pending;
    }

    late final Future<void> future;
    future = _disconnectInternal().whenComplete(() {
      if (identical(_disconnectFuture, future)) {
        _disconnectFuture = null;
      }
    });
    _disconnectFuture = future;
    return future;
  }

  Future<void> _disconnectInternal() async {
    _disconnectRequested = true;
    _connectionGeneration += 1;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectFuture = null;

    await _socketSubscription?.cancel();
    _socketSubscription = null;

    final socket = _socket;
    _socket = null;
    if (socket != null) {
      await socket
          .close(WebSocketStatus.normalClosure)
          .timeout(_disconnectTimeout, onTimeout: () {});
    }

    if (!_disposed) {
      _emitLifecycle(
        const ChatSocketLifecycleEvent(
          status: ChatSocketLifecycleStatus.disconnected,
        ),
      );
    }
  }

  Future<void> send(ChatClientEvent event) async {
    await ensureConnected().timeout(_sendConnectionTimeout);
    _sendOpen(event);
  }

  void _sendOpen(ChatClientEvent event) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) {
      throw StateError('Chat socket is not connected.');
    }

    final envelope = event.toEnvelope().toJson();
    socket.add(jsonEncode(envelope));
  }

  Future<void> reconnect() async {
    await disconnect();
    await ensureConnected();
  }

  Future<void> subscribeInbox() async {
    final wasSubscribed = _inboxSubscriptionCount > 0;
    _inboxSubscriptionCount += 1;
    if (wasSubscribed && isConnected) {
      return;
    }

    await send(const SubscribeInboxEvent());
  }

  Future<void> unsubscribeInbox() async {
    if (_inboxSubscriptionCount > 0) {
      _inboxSubscriptionCount -= 1;
    }

    if (_inboxSubscriptionCount > 0 || hasActiveSubscriptions) {
      return;
    }

    await disconnect();
  }

  Future<void> subscribeConversation(String conversationId) async {
    if (conversationId.isEmpty) {
      return;
    }

    final currentCount = _conversationSubscriptionCounts[conversationId] ?? 0;
    _conversationSubscriptionCounts[conversationId] = currentCount + 1;
    if (currentCount > 0 && isConnected) {
      return;
    }

    await send(
      SubscribeConversationEvent(conversationId: conversationId),
    );
  }

  Future<void> unsubscribeConversation(String conversationId) async {
    if (conversationId.isEmpty) {
      return;
    }

    final currentCount = _conversationSubscriptionCounts[conversationId] ?? 0;
    if (currentCount <= 1) {
      _conversationSubscriptionCounts.remove(conversationId);
    } else {
      _conversationSubscriptionCounts[conversationId] = currentCount - 1;
      return;
    }

    if (isConnected) {
      try {
        _sendOpen(
          UnsubscribeConversationEvent(conversationId: conversationId),
        );
      } catch (_) {}
    }

    if (hasActiveSubscriptions) {
      return;
    }

    await disconnect();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String clientMessageId,
    required String text,
  }) {
    return send(
      SendMessageEvent(
        conversationId: conversationId,
        clientMessageId: clientMessageId,
        text: text,
      ),
    );
  }

  Future<void> markRead({
    required String conversationId,
    required String lastReadMessageId,
  }) {
    return send(
      MarkReadEvent(
        conversationId: conversationId,
        lastReadMessageId: lastReadMessageId,
      ),
    );
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await disconnect();
    await _eventsController.close();
    await _lifecycleController.close();
  }

  Future<void> resumeIfNeeded() async {
    if (!hasActiveSubscriptions) {
      return;
    }

    final disconnecting = _disconnectFuture;
    if (disconnecting != null) {
      try {
        await disconnecting;
      } catch (_) {}
    }

    if (!hasActiveSubscriptions) {
      return;
    }

    await ensureConnected();
  }

  bool get hasActiveSubscriptions =>
      _inboxSubscriptionCount > 0 || _conversationSubscriptionCounts.isNotEmpty;

  Future<void> _connectInternal(int generation) async {
    _disconnectRequested = false;
    _emitLifecycle(
      ChatSocketLifecycleEvent(
        status: _reconnectAttempt == 0
            ? ChatSocketLifecycleStatus.connecting
            : ChatSocketLifecycleStatus.reconnecting,
        reconnectAttempt: _reconnectAttempt,
      ),
    );

    try {
      final session = await _authSessionStore.read();
      if (session == null || session.accessToken.isEmpty) {
        throw StateError('Chat socket requires an authenticated session.');
      }

      final wsUrl = _buildWsUrl();
      final token = session.accessToken;

      final socket = await WebSocket.connect(
        wsUrl,
        headers: <String, dynamic>{
          'Authorization': 'Bearer $token',
        },
      ).timeout(_connectTimeout);
      socket.pingInterval = const Duration(seconds: 20);

      if (_isStaleConnection(generation)) {
        await socket
            .close(WebSocketStatus.normalClosure)
            .timeout(_disconnectTimeout, onTimeout: () {});
        return;
      }

      _socket = socket;
      _socketSubscription = socket.listen(
        _handleIncomingData,
        onDone: () => _handleSocketDone(socket, generation),
        onError: (Object error) =>
            _handleSocketError(socket, generation, error),
        cancelOnError: false,
      );

      _reconnectAttempt = 0;
      _emitLifecycle(
        const ChatSocketLifecycleEvent(
          status: ChatSocketLifecycleStatus.connected,
        ),
      );
      await _restoreSubscriptions();
    } catch (error) {
      if (_isStaleConnection(generation)) {
        return;
      }

      final isAuthenticationFailure = _isAuthenticationFailure(error);
      _emitLifecycle(
        ChatSocketLifecycleEvent(
          status: ChatSocketLifecycleStatus.error,
          errorMessage: error.toString(),
          reconnectAttempt: _reconnectAttempt,
        ),
      );
      if (!isAuthenticationFailure && hasActiveSubscriptions) {
        _scheduleReconnect();
      }
    } finally {
      if (_connectionGeneration == generation) {
        _connectFuture = null;
      }
    }
  }

  void _handleIncomingData(dynamic data) {
    if (data is! String) {
      return;
    }

    try {
      final decoded = jsonDecode(data);
      final event = ChatServerEvent.fromJson(decoded);
      _emitEvent(event);
    } catch (_) {
      _emitEvent(
        const UnknownChatServerEvent(
          type: 'invalid_event',
          payload: <String, dynamic>{},
        ),
      );
    }
  }

  void _handleSocketDone(WebSocket socket, int generation) {
    if (!_isCurrentConnection(socket, generation)) {
      return;
    }

    _socketSubscription = null;
    _socket = null;

    if (_disconnectRequested) {
      _emitLifecycle(
        const ChatSocketLifecycleEvent(
          status: ChatSocketLifecycleStatus.disconnected,
        ),
      );
      return;
    }

    _scheduleReconnect();
  }

  void _handleSocketError(WebSocket socket, int generation, Object error) {
    if (!_isCurrentConnection(socket, generation)) {
      return;
    }

    _socketSubscription = null;
    _socket = null;
    _emitLifecycle(
      ChatSocketLifecycleEvent(
        status: ChatSocketLifecycleStatus.error,
        errorMessage: error.toString(),
        reconnectAttempt: _reconnectAttempt,
      ),
    );

    if (_disconnectRequested) {
      return;
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed ||
        _disconnectRequested ||
        !hasActiveSubscriptions ||
        _connectFuture != null ||
        _reconnectTimer != null) {
      return;
    }

    _reconnectAttempt += 1;
    final delaySeconds = _reconnectAttempt.clamp(1, 5);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectTimer = null;
      Future<void>(() async {
        try {
          await ensureConnected();
        } catch (_) {
          // lifecycleEvents already contain error details
        }
      });
    });
  }

  Future<void> _restoreSubscriptions() async {
    if (_inboxSubscriptionCount > 0) {
      try {
        _sendOpen(const SubscribeInboxEvent());
      } catch (_) {}
    }

    for (final conversationId in _conversationSubscriptionCounts.keys) {
      try {
        _sendOpen(
          SubscribeConversationEvent(conversationId: conversationId),
        );
      } catch (_) {}
    }
  }

  String _buildWsUrl() {
    final baseUri = Uri.parse(ApiConstants.baseUrl);
    final scheme = switch (baseUri.scheme) {
      'https' => 'wss',
      _ => 'ws',
    };

    return baseUri
        .replace(
          scheme: scheme,
          path: ApiEndpoints.chatWs,
          queryParameters: null,
        )
        .toString();
  }

  void _emitLifecycle(ChatSocketLifecycleEvent event) {
    if (!_lifecycleController.isClosed) {
      _lifecycleController.add(event);
    }
  }

  void _emitEvent(ChatServerEvent event) {
    if (!_eventsController.isClosed) {
      _eventsController.add(event);
    }
  }

  bool _isStaleConnection(int generation) {
    return _disposed ||
        _disconnectRequested ||
        generation != _connectionGeneration;
  }

  bool _isCurrentConnection(WebSocket socket, int generation) {
    return !_disposed &&
        generation == _connectionGeneration &&
        identical(_socket, socket);
  }

  bool _isAuthenticationFailure(Object error) {
    final message = error.toString();
    return message.contains('401') || message.contains('authenticated session');
  }
}
