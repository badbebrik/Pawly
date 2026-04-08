import '../../../core/network/clients/chat_api_client.dart';
import '../../../core/network/models/chat_models.dart';
import 'chat_repository_models.dart';

class ChatRepository {
  ChatRepository({required ChatApiClient chatApiClient})
      : _chatApiClient = chatApiClient;

  final ChatApiClient _chatApiClient;

  Future<ChatListItem> openConversation(OpenDirectChatInput input) async {
    final response = await _chatApiClient.openConversation(
      OpenChatConversationPayload(
        petId: input.petId,
        otherUserId: input.otherUserId,
      ),
    );

    return _mapConversation(response);
  }

  Future<ChatInboxPageData> listConversations({
    String? petId,
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _chatApiClient.listConversations(
      petId: petId,
      cursor: cursor,
      limit: limit,
    );

    return ChatInboxPageData(
      items: response.items.map(_mapConversation).toList(growable: false),
      nextCursor: response.nextCursor,
    );
  }

  Future<ChatUnreadState> getUnreadSummary() async {
    final response = await _chatApiClient.getUnreadSummary();

    return ChatUnreadState(
      unreadConversations: response.unreadConversations,
      unreadMessages: response.unreadMessages,
    );
  }

  Future<ChatListItem> getConversation(String conversationId) async {
    final response = await _chatApiClient.getConversation(conversationId);
    return _mapConversation(response);
  }

  Future<ChatMessagePageData> getMessages(
    String conversationId, {
    String? beforeMessageId,
    int limit = 50,
  }) async {
    final response = await _chatApiClient.getMessages(
      conversationId,
      beforeMessageId: beforeMessageId,
      limit: limit,
    );

    return ChatMessagePageData(
      conversationId: response.conversationId,
      messages: response.messages.map(_mapMessage).toList(growable: false),
      hasMore: response.hasMore,
    );
  }

  Future<String> markRead(MarkChatReadInput input) async {
    final response = await _chatApiClient.markRead(
      input.conversationId,
      MarkChatConversationReadPayload(
        lastReadMessageId: input.lastReadMessageId,
      ),
    );

    return response.lastReadMessageId;
  }

  ChatListItem mapConversation(ChatConversation source) {
    return _mapConversation(source);
  }

  ChatMessageItem mapMessage(ChatMessage source) {
    return _mapMessage(source);
  }

  ChatListItem _mapConversation(ChatConversation source) {
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

  ChatMessageItem _mapMessage(ChatMessage source) {
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
}
