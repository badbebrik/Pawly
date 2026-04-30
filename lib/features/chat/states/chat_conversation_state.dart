import '../models/chat_models.dart';

class ChatConversationState {
  const ChatConversationState({
    required this.currentUserId,
    required this.conversation,
    required this.messages,
    required this.hasMoreMessages,
    required this.isLoadingMoreMessages,
    required this.isMarkingRead,
    required this.isSendingMessage,
  });

  final String currentUserId;
  final ChatListItem conversation;
  final List<ChatMessageItem> messages;
  final bool hasMoreMessages;
  final bool isLoadingMoreMessages;
  final bool isMarkingRead;
  final bool isSendingMessage;

  String? get lastReadableMessageId {
    for (final message in messages.reversed) {
      if (message.deliveryStatus != ChatMessageDeliveryStatus.sent) {
        continue;
      }
      if (message.isLocal) {
        continue;
      }
      return message.messageId;
    }

    final fallback = conversation.lastMessageId;
    if (fallback == null ||
        fallback.isEmpty ||
        fallback.startsWith(chatLocalMessageIdPrefix)) {
      return null;
    }

    return fallback;
  }

  bool get canMarkRead =>
      lastReadableMessageId != null && lastReadableMessageId!.isNotEmpty;

  bool isMessageReadByPeer(String messageId) {
    final peerReadMessageId = conversation.otherUserLastReadMessageId;
    if (peerReadMessageId == null || peerReadMessageId.isEmpty) {
      return false;
    }

    final readIndex = messages.indexWhere(
      (message) => message.messageId == peerReadMessageId,
    );
    if (readIndex >= 0) {
      final messageIndex = messages.indexWhere(
        (message) => message.messageId == messageId,
      );
      return messageIndex >= 0 && messageIndex <= readIndex;
    }

    return messageId == peerReadMessageId;
  }

  ChatConversationState copyWith({
    String? currentUserId,
    ChatListItem? conversation,
    List<ChatMessageItem>? messages,
    bool? hasMoreMessages,
    bool? isLoadingMoreMessages,
    bool? isMarkingRead,
    bool? isSendingMessage,
  }) {
    return ChatConversationState(
      currentUserId: currentUserId ?? this.currentUserId,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMoreMessages:
          isLoadingMoreMessages ?? this.isLoadingMoreMessages,
      isMarkingRead: isMarkingRead ?? this.isMarkingRead,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
    );
  }
}
