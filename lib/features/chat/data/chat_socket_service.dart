import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/session/auth_session_store.dart';
import 'chat_socket_models.dart';

class ChatSocketService {
  ChatSocketService({
    required AuthSessionStore authSessionStore,
  }) : _authSessionStore = authSessionStore;

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
      _log('ensureConnected: reuse pending connect future');
      return pending;
    }
    if (isConnected) {
      _log('ensureConnected: socket already connected');
      return Future<void>.value();
    }

    _log('ensureConnected: open new socket connection');
    _connectFuture = _connectInternal();
    return _connectFuture!;
  }

  Future<void> disconnect() async {
    _log('disconnect: requested');
    _disconnectRequested = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectFuture = null;

    await _socketSubscription?.cancel();
    _socketSubscription = null;

    final socket = _socket;
    _socket = null;
    if (socket != null) {
      await socket.close(WebSocketStatus.normalClosure);
    }

    _emitLifecycle(
      const ChatSocketLifecycleEvent(
        status: ChatSocketLifecycleStatus.disconnected,
      ),
    );
  }

  Future<void> send(ChatClientEvent event) async {
    await ensureConnected();

    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) {
      _log('send: socket is not connected for event=${event.type}');
      throw StateError('Chat socket is not connected.');
    }

    final envelope = event.toEnvelope().toJson();
    _log('send: type=${event.type} payload=${jsonEncode(envelope['payload'])}');
    socket.add(jsonEncode(envelope));
  }

  Future<void> subscribeInbox() async {
    _inboxSubscribed = true;
    _log('subscribeInbox');
    await send(const SubscribeInboxEvent());
  }

  Future<void> subscribeConversation(String conversationId) async {
    if (conversationId.isEmpty) {
      return;
    }

    _conversationSubscriptions.add(conversationId);
    _log('subscribeConversation: conversationId=$conversationId');
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
      _log(
        'unsubscribeConversation: skip send because socket disconnected '
        'conversationId=$conversationId',
      );
      return;
    }

    _log('unsubscribeConversation: conversationId=$conversationId');
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
    _log('connect: start attempt=${_reconnectAttempt + 1}');
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
        _log('connect: no authenticated session');
        throw StateError('Chat socket requires an authenticated session.');
      }

      final wsUrl = _buildWsUrl();
      final token = session.accessToken;
      _log(
        'connect: url=$wsUrl tokenLength=${token.length} '
        'subscriptions=${_conversationSubscriptions.length} inbox=$_inboxSubscribed',
      );

      final socket = await WebSocket.connect(
        wsUrl,
        headers: <String, dynamic>{
          'Authorization': 'Bearer $token',
        },
      );
      socket.pingInterval = const Duration(seconds: 20);
      _log('connect: socket connected, pingInterval=20s');

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
      _log('connect: connected, restoring subscriptions');
      await _restoreSubscriptions();
    } catch (error) {
      final isUnauthorized = error.toString().contains('401');
      _log(
        'connect: failed unauthorized=$isUnauthorized error=$error',
      );
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
      _log('incoming: non-string payload type=${data.runtimeType}');
      return;
    }

    try {
      final decoded = jsonDecode(data);
      final event = ChatServerEvent.fromJson(decoded);
      _log('incoming: type=${event.type} raw=$data');
      _eventsController.add(event);
    } catch (error) {
      _log('incoming: failed to decode raw=$data error=$error');
      _eventsController.add(
        const UnknownChatServerEvent(
          type: 'invalid_event',
          payload: <String, dynamic>{},
        ),
      );
    }
  }

  void _handleSocketDone() {
    _log('socket done: disconnectRequested=$_disconnectRequested');
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
    _log('socket error: $error');
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
      _log(
        'scheduleReconnect: skip disconnectRequested=$_disconnectRequested '
        'hasTimer=${_reconnectTimer != null}',
      );
      return;
    }

    _reconnectAttempt += 1;
    final delaySeconds = _reconnectAttempt.clamp(1, 5);
    _log(
      'scheduleReconnect: attempt=$_reconnectAttempt delay=${delaySeconds}s',
    );
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _reconnectTimer = null;
      Future<void>(() async {
        try {
          _log('scheduleReconnect: firing attempt=$_reconnectAttempt');
          await ensureConnected();
        } catch (_) {
          // lifecycleEvents already contain error details
        }
      });
    });
  }

  Future<void> _restoreSubscriptions() async {
    _log(
      'restoreSubscriptions: inbox=$_inboxSubscribed '
      'conversations=${_conversationSubscriptions.length}',
    );
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
    _log(
      'lifecycle: status=${event.status.name} '
      'attempt=${event.reconnectAttempt} error=${event.errorMessage}',
    );
    if (!_lifecycleController.isClosed) {
      _lifecycleController.add(event);
    }
  }

  void _log(String message) {
    debugPrint('[chat/ws] $message');
  }
}
