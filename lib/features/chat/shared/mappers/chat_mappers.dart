import '../../../../core/network/models/chat_models.dart' as network;
import '../../models/chat_models.dart';

ChatListItem chatListItemFromNetwork(network.ChatConversation source) {
  return ChatListItem(
    conversationId: source.conversationId,
    pet: ChatPetContext(
      petId: source.pet.petId,
      name: source.pet.name,
      avatarUrl: source.pet.avatarUrl,
    ),
    peer: ChatPeer(
      userId: source.otherUser.userId,
      displayName: source.otherUser.displayName,
      avatarUrl: source.otherUser.avatarUrl,
    ),
    lastMessageId: source.lastMessageId,
    lastMessageAt: source.lastMessageAt,
    lastMessagePreview: source.lastMessagePreview,
    lastMessageSenderId: source.lastMessageSenderId,
    lastReadMessageId: source.lastReadMessageId,
    otherUserLastReadMessageId: source.otherUserLastReadMessageId,
    unreadCount: source.unreadCount,
    otherUserInChat: source.otherUserInChat,
    canSend: source.canSend,
  );
}

ChatMessageItem chatMessageItemFromNetwork(network.ChatMessage source) {
  return ChatMessageItem(
    messageId: source.messageId,
    conversationId: source.conversationId,
    senderUserId: source.senderUserId,
    clientMessageId: source.clientMsgId,
    text: source.text,
    createdAt: source.createdAt,
    deliveryStatus: ChatMessageDeliveryStatus.sent,
  );
}

ChatUnreadSummary chatUnreadSummaryFromNetwork(
    network.ChatUnreadSummary source) {
  return ChatUnreadSummary(
    unreadConversations: source.unreadConversations,
    unreadMessages: source.unreadMessages,
  );
}
