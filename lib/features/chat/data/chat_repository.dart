import '../../../core/network/clients/chat_api_client.dart';
import '../../../core/network/models/chat_models.dart' as network;
import '../models/chat_models.dart';
import '../shared/mappers/chat_mappers.dart';

class ChatRepository {
  ChatRepository({required ChatApiClient chatApiClient})
      : _chatApiClient = chatApiClient;

  final ChatApiClient _chatApiClient;

  Future<ChatListItem> openConversation(OpenDirectChatInput input) async {
    final response = await _chatApiClient.openConversation(
      network.OpenChatConversationPayload(
        petId: input.petId,
        otherUserId: input.otherUserId,
      ),
    );

    return chatListItemFromNetwork(response);
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
      items:
          response.items.map(chatListItemFromNetwork).toList(growable: false),
      nextCursor: response.nextCursor,
    );
  }

  Future<ChatUnreadSummary> getUnreadSummary() async {
    final response = await _chatApiClient.getUnreadSummary();

    return chatUnreadSummaryFromNetwork(response);
  }

  Future<ChatListItem> getConversation(String conversationId) async {
    final response = await _chatApiClient.getConversation(conversationId);
    return chatListItemFromNetwork(response);
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
      messages: response.messages
          .map(chatMessageItemFromNetwork)
          .toList(growable: false),
      hasMore: response.hasMore,
    );
  }

  Future<String> markRead(MarkChatReadInput input) async {
    final response = await _chatApiClient.markRead(
      input.conversationId,
      network.MarkChatConversationReadPayload(
        lastReadMessageId: input.lastReadMessageId,
      ),
    );

    return response.lastReadMessageId;
  }
}
