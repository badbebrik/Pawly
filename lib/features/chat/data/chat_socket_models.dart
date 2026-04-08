import 'package:equatable/equatable.dart';

import '../../../core/network/models/chat_models.dart';
import '../../../core/network/models/json_map.dart';
import '../../../core/network/models/json_parsers.dart';

class ChatSocketEnvelope {
  const ChatSocketEnvelope({
    required this.type,
    required this.payload,
  });

  final String type;
  final JsonMap payload;

  JsonMap toJson() => <String, dynamic>{
        'type': type,
        'payload': payload,
      };
}

abstract class ChatClientEvent extends Equatable {
  const ChatClientEvent(this.type);

  final String type;

  JsonMap toPayload();

  ChatSocketEnvelope toEnvelope() => ChatSocketEnvelope(
        type: type,
        payload: toPayload(),
      );

  @override
  List<Object?> get props => <Object?>[type, toPayload()];
}

class SubscribeInboxEvent extends ChatClientEvent {
  const SubscribeInboxEvent() : super('subscribe_inbox');

  @override
  JsonMap toPayload() => <String, dynamic>{};
}

class SubscribeConversationEvent extends ChatClientEvent {
  const SubscribeConversationEvent({
    required this.conversationId,
  }) : super('subscribe_conversation');

  final String conversationId;

  @override
  JsonMap toPayload() => <String, dynamic>{
        'conversation_id': conversationId,
      };

  @override
  List<Object?> get props => <Object?>[type, conversationId];
}

class UnsubscribeConversationEvent extends ChatClientEvent {
  const UnsubscribeConversationEvent({
    required this.conversationId,
  }) : super('unsubscribe_conversation');

  final String conversationId;

  @override
  JsonMap toPayload() => <String, dynamic>{
        'conversation_id': conversationId,
      };

  @override
  List<Object?> get props => <Object?>[type, conversationId];
}

class SendMessageEvent extends ChatClientEvent {
  const SendMessageEvent({
    required this.conversationId,
    required this.clientMessageId,
    required this.text,
  }) : super('send_message');

  final String conversationId;
  final String clientMessageId;
  final String text;

  @override
  JsonMap toPayload() => <String, dynamic>{
        'conversation_id': conversationId,
        'client_msg_id': clientMessageId,
        'text': text,
      };

  @override
  List<Object?> get props => <Object?>[
        type,
        conversationId,
        clientMessageId,
        text,
      ];
}

class MarkReadEvent extends ChatClientEvent {
  const MarkReadEvent({
    required this.conversationId,
    required this.lastReadMessageId,
  }) : super('mark_read');

  final String conversationId;
  final String lastReadMessageId;

  @override
  JsonMap toPayload() => <String, dynamic>{
        'conversation_id': conversationId,
        'last_read_message_id': lastReadMessageId,
      };

  @override
  List<Object?> get props => <Object?>[
        type,
        conversationId,
        lastReadMessageId,
      ];
}

abstract class ChatServerEvent extends Equatable {
  const ChatServerEvent(this.type);

  final String type;

  factory ChatServerEvent.fromJson(Object? data) {
    final json = asJsonMap(data);
    final type = asString(json['type']);
    final payload = asJsonMap(json['payload']);

    return switch (type) {
      'message_ack' => MessageAckEvent(
          message: ChatMessage.fromJson(payload),
        ),
      'message_new' => MessageNewEvent(
          message: ChatMessage.fromJson(payload),
        ),
      'read_updated' => ReadUpdatedEvent.fromPayload(payload),
      'conversation_updated' => ConversationUpdatedEvent(
          conversation: ChatConversation.fromJson(payload),
        ),
      'conversation_presence_updated' =>
        ConversationPresenceUpdatedEvent.fromPayload(payload),
      'global_unread_updated' => GlobalUnreadUpdatedEvent(
          summary: ChatUnreadSummary.fromJson(payload),
        ),
      'server_error' => ChatServerErrorEvent.fromPayload(payload),
      _ => UnknownChatServerEvent(type: type, payload: payload),
    };
  }

  @override
  List<Object?> get props => <Object?>[type];
}

class MessageAckEvent extends ChatServerEvent {
  const MessageAckEvent({required this.message}) : super('message_ack');

  final ChatMessage message;

  @override
  List<Object?> get props => <Object?>[type, message];
}

class MessageNewEvent extends ChatServerEvent {
  const MessageNewEvent({required this.message}) : super('message_new');

  final ChatMessage message;

  @override
  List<Object?> get props => <Object?>[type, message];
}

class ReadUpdatedEvent extends ChatServerEvent {
  const ReadUpdatedEvent({
    required this.conversationId,
    required this.userId,
    required this.lastReadMessageId,
  }) : super('read_updated');

  final String conversationId;
  final String userId;
  final String lastReadMessageId;

  factory ReadUpdatedEvent.fromPayload(Object? data) {
    final json = asJsonMap(data);

    return ReadUpdatedEvent(
      conversationId: asString(json['conversation_id']),
      userId: asString(json['user_id']),
      lastReadMessageId: asString(json['last_read_message_id']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        type,
        conversationId,
        userId,
        lastReadMessageId,
      ];
}

class ConversationUpdatedEvent extends ChatServerEvent {
  const ConversationUpdatedEvent({required this.conversation})
      : super('conversation_updated');

  final ChatConversation conversation;

  @override
  List<Object?> get props => <Object?>[type, conversation];
}

class ConversationPresenceUpdatedEvent extends ChatServerEvent {
  const ConversationPresenceUpdatedEvent({
    required this.conversationId,
    required this.userId,
    required this.isInChat,
  }) : super('conversation_presence_updated');

  final String conversationId;
  final String userId;
  final bool isInChat;

  factory ConversationPresenceUpdatedEvent.fromPayload(Object? data) {
    final json = asJsonMap(data);

    return ConversationPresenceUpdatedEvent(
      conversationId: asString(json['conversation_id']),
      userId: asString(json['user_id']),
      isInChat: asBool(json['is_in_chat']),
    );
  }

  @override
  List<Object?> get props => <Object?>[type, conversationId, userId, isInChat];
}

class GlobalUnreadUpdatedEvent extends ChatServerEvent {
  const GlobalUnreadUpdatedEvent({required this.summary})
      : super('global_unread_updated');

  final ChatUnreadSummary summary;

  @override
  List<Object?> get props => <Object?>[type, summary];
}

class ChatServerErrorEvent extends ChatServerEvent {
  const ChatServerErrorEvent({
    required this.code,
    required this.message,
  }) : super('server_error');

  final String code;
  final String message;

  factory ChatServerErrorEvent.fromPayload(Object? data) {
    final json = asJsonMap(data);

    return ChatServerErrorEvent(
      code: asString(json['code']),
      message: asString(json['message']),
    );
  }

  @override
  List<Object?> get props => <Object?>[type, code, message];
}

class UnknownChatServerEvent extends ChatServerEvent {
  const UnknownChatServerEvent({
    required String type,
    required this.payload,
  }) : super(type);

  final JsonMap payload;

  @override
  List<Object?> get props => <Object?>[type, payload];
}

enum ChatSocketLifecycleStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class ChatSocketLifecycleEvent extends Equatable {
  const ChatSocketLifecycleEvent({
    required this.status,
    this.errorMessage,
    this.reconnectAttempt = 0,
  });

  final ChatSocketLifecycleStatus status;
  final String? errorMessage;
  final int reconnectAttempt;

  @override
  List<Object?> get props => <Object?>[
        status,
        errorMessage,
        reconnectAttempt,
      ];
}
