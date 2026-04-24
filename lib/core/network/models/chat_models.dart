import 'json_map.dart';
import 'json_parsers.dart';

class ChatPetBrief {
  const ChatPetBrief({
    required this.petId,
    required this.name,
    required this.avatarUrl,
  });

  final String petId;
  final String name;
  final String? avatarUrl;

  factory ChatPetBrief.fromJson(Object? data) {
    final json = asJsonMap(data);

    return ChatPetBrief(
      petId: asString(json['pet_id']),
      name: asString(json['name']),
      avatarUrl: asNullableString(json['avatar_url']),
    );
  }
}

class ChatUserBrief {
  const ChatUserBrief({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;

  factory ChatUserBrief.fromJson(Object? data) {
    final json = asJsonMap(data);

    return ChatUserBrief(
      userId: asString(json['user_id']),
      displayName: asString(json['display_name']),
      avatarUrl: asNullableString(json['avatar_url']),
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.conversationId,
    required this.pet,
    required this.otherUser,
    required this.lastMessageId,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.lastMessageSenderId,
    required this.lastReadMessageId,
    required this.otherUserLastReadMessageId,
    required this.unreadCount,
    required this.otherUserInChat,
    required this.canSend,
  });

  final String conversationId;
  final ChatPetBrief pet;
  final ChatUserBrief otherUser;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final String? lastMessageSenderId;
  final String? lastReadMessageId;
  final String? otherUserLastReadMessageId;
  final int unreadCount;
  final bool otherUserInChat;
  final bool canSend;

  factory ChatConversation.fromJson(Object? data) {
    final json = asJsonMap(data);
    final envelope = json['conversation'];
    if (envelope != null) {
      return ChatConversation.fromJson(envelope);
    }

    return ChatConversation(
      conversationId: asString(json['conversation_id']),
      pet: ChatPetBrief.fromJson(json['pet']),
      otherUser: ChatUserBrief.fromJson(json['other_user']),
      lastMessageId: asNullableString(json['last_message_id']),
      lastMessageAt: asDateTime(json['last_message_at']),
      lastMessagePreview: asNullableString(json['last_message_preview']),
      lastMessageSenderId: asNullableString(json['last_message_sender_id']),
      lastReadMessageId: asNullableString(json['last_read_message_id']),
      otherUserLastReadMessageId:
          asNullableString(json['other_user_last_read_message_id']),
      unreadCount: asInt(json['unread_count']),
      otherUserInChat: asBool(json['other_user_in_chat']),
      canSend: asBool(json['can_send']),
    );
  }
}

class ChatConversationListResponse {
  const ChatConversationListResponse({
    required this.items,
    required this.nextCursor,
  });

  final List<ChatConversation> items;
  final String? nextCursor;

  factory ChatConversationListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);

    return ChatConversationListResponse(
      items: asJsonMapList(json['items'])
          .map(ChatConversation.fromJson)
          .toList(growable: false),
      nextCursor: asNullableString(json['next_cursor']),
    );
  }
}

class ChatUnreadSummary {
  const ChatUnreadSummary({
    required this.unreadConversations,
    required this.unreadMessages,
  });

  final int unreadConversations;
  final int unreadMessages;

  factory ChatUnreadSummary.fromJson(Object? data) {
    final json = asJsonMap(data);

    return ChatUnreadSummary(
      unreadConversations: asInt(json['unread_conversations']),
      unreadMessages: asInt(json['unread_messages']),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.conversationId,
    required this.senderUserId,
    required this.clientMsgId,
    required this.text,
    required this.createdAt,
  });

  final String messageId;
  final String conversationId;
  final String senderUserId;
  final String? clientMsgId;
  final String text;
  final DateTime? createdAt;

  factory ChatMessage.fromJson(Object? data) {
    final json = asJsonMap(data);

    return ChatMessage(
      messageId: asString(json['message_id']),
      conversationId: asString(json['conversation_id']),
      senderUserId: asString(json['sender_user_id']),
      clientMsgId: asNullableString(json['client_msg_id']),
      text: asString(json['text']),
      createdAt: asDateTime(json['created_at']),
    );
  }
}

class ChatMessagesResponse {
  const ChatMessagesResponse({
    required this.conversationId,
    required this.messages,
    required this.hasMore,
  });

  final String conversationId;
  final List<ChatMessage> messages;
  final bool hasMore;

  factory ChatMessagesResponse.fromJson(Object? data) {
    final json = asJsonMap(data);

    return ChatMessagesResponse(
      conversationId: asString(json['conversation_id']),
      messages: asJsonMapList(json['messages'])
          .map(ChatMessage.fromJson)
          .toList(growable: false),
      hasMore: asBool(json['has_more']),
    );
  }
}

class OpenChatConversationPayload {
  const OpenChatConversationPayload({
    required this.petId,
    required this.otherUserId,
  });

  final String petId;
  final String otherUserId;

  JsonMap toJson() => <String, dynamic>{
        'pet_id': petId,
        'other_user_id': otherUserId,
      };
}

class MarkChatConversationReadPayload {
  const MarkChatConversationReadPayload({
    required this.lastReadMessageId,
  });

  final String lastReadMessageId;

  JsonMap toJson() => <String, dynamic>{
        'last_read_message_id': lastReadMessageId,
      };
}

class MarkChatConversationReadResponse {
  const MarkChatConversationReadResponse({
    required this.conversationId,
    required this.lastReadMessageId,
  });

  final String conversationId;
  final String lastReadMessageId;

  factory MarkChatConversationReadResponse.fromJson(Object? data) {
    final json = asJsonMap(data);

    return MarkChatConversationReadResponse(
      conversationId: asString(json['conversation_id']),
      lastReadMessageId: asString(json['last_read_message_id']),
    );
  }
}
