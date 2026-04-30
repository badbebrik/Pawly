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
  Timer? _reconnectTimer;

  bool _disconnectRequested = false;
  bool _inboxSubscribed = false;
  int _reconnectAttempt = 0;
  final Set<String> _conversationSubscriptions = <String>{};

  Stream<ChatServerEvent> get events => _eventsController.stream;
  Stream<ChatSocketLifecycleEvent> get lifecycleEvents =>
      _lifecycleController.stream;

  bool get isConnected =>
      _socket != null && _socket!.readyState == WebSocket.open;

  Future<void> ensureConnected() {
    final pending = _connectFuture;
    if (pending != null) {
      return pending;
    }
    if (isConnected) {
      return Future<void>.value();
    }

    _connectFuture = _connectInternal();
    return _connectFuture!;
  }

  Future<void> disconnect() async {
    _disconnectRequested = true;
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

    _emitLifecycle(
      const ChatSocketLifecycleEvent(
        status: ChatSocketLifecycleStatus.disconnected,
      ),
    );
  }

  Future<void> send(ChatClientEvent event) async {
    await ensureConnected().timeout(_sendConnectionTimeout);

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
    _inboxSubscribed = true;
    await send(const SubscribeInboxEvent());
  }

  Future<void> subscribeConversation(String conversationId) async {
    if (conversationId.isEmpty) {
      return;
    }

    _conversationSubscriptions.add(conversationId);
    await send(
      SubscribeConversationEvent(conversationId: conversationId),
    );
  }

  Future<void> unsubscribeConversation(String conversationId) async {
    if (conversationId.isEmpty) {
      return;
    }

    _conversationSubscriptions.remove(conversationId);
    if (!isConnected) {
      return;
    }

    await send(
      UnsubscribeConversationEvent(conversationId: conversationId),
    );
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
    await disconnect();
    await _eventsController.close();
    await _lifecycleController.close();
  }

  Future<void> _connectInternal() async {
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

      _socket = socket;
      _socketSubscription = socket.listen(
        _handleIncomingData,
        onDone: _handleSocketDone,
        onError: _handleSocketError,
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
      final isUnauthorized = error.toString().contains('401');
      _emitLifecycle(
        ChatSocketLifecycleEvent(
          status: ChatSocketLifecycleStatus.error,
          errorMessage: error.toString(),
          reconnectAttempt: _reconnectAttempt,
        ),
      );
      if (!isUnauthorized) {
        _scheduleReconnect();
      }
    } finally {
      _connectFuture = null;
    }
  }

  void _handleIncomingData(dynamic data) {
    if (data is! String) {
      return;
    }

    try {
      final decoded = jsonDecode(data);
      final event = ChatServerEvent.fromJson(decoded);
      _eventsController.add(event);
    } catch (_) {
      _eventsController.add(
        const UnknownChatServerEvent(
          type: 'invalid_event',
          payload: <String, dynamic>{},
        ),
      );
    }
  }

  void _handleSocketDone() {
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

  void _handleSocketError(Object error) {
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
    if (_disconnectRequested || _reconnectTimer != null) {
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
    if (_inboxSubscribed) {
      await send(const SubscribeInboxEvent());
    }

    for (final conversationId in _conversationSubscriptions) {
      await send(
        SubscribeConversationEvent(conversationId: conversationId),
      );
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
}
