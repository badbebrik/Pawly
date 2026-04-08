enum ChatMessageDeliveryStatus {
  sent,
  sending,
  failed,
}

class ChatPeer {
  const ChatPeer({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
}

class ChatPetContext {
  const ChatPetContext({
    required this.petId,
    required this.name,
    required this.avatarUrl,
  });

  final String petId;
  final String name;
  final String? avatarUrl;
}

class ChatListItem {
  const ChatListItem({
    required this.conversationId,
    required this.pet,
    required this.peer,
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
  final ChatPetContext pet;
  final ChatPeer peer;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final String? lastMessageSenderId;
  final String? lastReadMessageId;
  final String? otherUserLastReadMessageId;
  final int unreadCount;
  final bool otherUserInChat;
  final bool canSend;

  bool get hasUnread => unreadCount > 0;
}

class ChatInboxPageData {
  const ChatInboxPageData({
    required this.items,
    required this.nextCursor,
  });

  final List<ChatListItem> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;
}

class ChatUnreadState {
  const ChatUnreadState({
    required this.unreadConversations,
    required this.unreadMessages,
  });

  final int unreadConversations;
  final int unreadMessages;

  bool get hasUnread => unreadConversations > 0 || unreadMessages > 0;
}

class ChatMessageItem {
  const ChatMessageItem({
    required this.messageId,
    required this.conversationId,
    required this.senderUserId,
    required this.clientMessageId,
    required this.text,
    required this.createdAt,
    this.deliveryStatus = ChatMessageDeliveryStatus.sent,
  });

  final String messageId;
  final String conversationId;
  final String senderUserId;
  final String? clientMessageId;
  final String text;
  final DateTime? createdAt;
  final ChatMessageDeliveryStatus deliveryStatus;

  bool get isSending => deliveryStatus == ChatMessageDeliveryStatus.sending;
  bool get hasFailed => deliveryStatus == ChatMessageDeliveryStatus.failed;

  ChatMessageItem copyWith({
    String? messageId,
    String? conversationId,
    String? senderUserId,
    String? clientMessageId,
    String? text,
    DateTime? createdAt,
    ChatMessageDeliveryStatus? deliveryStatus,
  }) {
    return ChatMessageItem(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderUserId: senderUserId ?? this.senderUserId,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }
}

class ChatMessagePageData {
  const ChatMessagePageData({
    required this.conversationId,
    required this.messages,
    required this.hasMore,
  });

  final String conversationId;
  final List<ChatMessageItem> messages;
  final bool hasMore;
}

class OpenDirectChatInput {
  const OpenDirectChatInput({
    required this.petId,
    required this.otherUserId,
  });

  final String petId;
  final String otherUserId;
}

class MarkChatReadInput {
  const MarkChatReadInput({
    required this.conversationId,
    required this.lastReadMessageId,
  });

  final String conversationId;
  final String lastReadMessageId;
}
