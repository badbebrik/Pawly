import '../api_client.dart';
import '../api_context.dart';
import '../api_endpoints.dart';
import '../models/chat_models.dart';

class ChatApiClient {
  ChatApiClient(this._apiClient);

  final ApiClient _apiClient;

  static const _withToken = ApiRequestOptions(requiresAccessToken: true);

  Future<ChatConversation> openConversation(
    OpenChatConversationPayload payload,
  ) {
    return _apiClient.post<ChatConversation>(
      ApiEndpoints.chatConversationsOpen,
      data: payload.toJson(),
      requestOptions: _withToken,
      decoder: ChatConversation.fromJson,
    );
  }

  Future<ChatConversationListResponse> listConversations({
    String? petId,
    String? cursor,
    int? limit,
  }) {
    return _apiClient.get<ChatConversationListResponse>(
      ApiEndpoints.chatConversations,
      queryParameters: <String, dynamic>{
        if (petId != null && petId.isNotEmpty) 'pet_id': petId,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (limit != null) 'limit': limit,
      },
      requestOptions: _withToken,
      decoder: ChatConversationListResponse.fromJson,
    );
  }

  Future<ChatUnreadSummary> getUnreadSummary() {
    return _apiClient.get<ChatUnreadSummary>(
      ApiEndpoints.chatUnreadSummary,
      requestOptions: _withToken,
      decoder: ChatUnreadSummary.fromJson,
    );
  }

  Future<ChatConversation> getConversation(String conversationId) {
    return _apiClient.get<ChatConversation>(
      ApiEndpoints.chatConversationById(conversationId),
      requestOptions: _withToken,
      decoder: ChatConversation.fromJson,
    );
  }

  Future<ChatMessagesResponse> getMessages(
    String conversationId, {
    String? beforeMessageId,
    int? limit,
  }) {
    return _apiClient.get<ChatMessagesResponse>(
      ApiEndpoints.chatConversationMessages(conversationId),
      queryParameters: <String, dynamic>{
        if (beforeMessageId != null && beforeMessageId.isNotEmpty)
          'before_message_id': beforeMessageId,
        if (limit != null) 'limit': limit,
      },
      requestOptions: _withToken,
      decoder: ChatMessagesResponse.fromJson,
    );
  }

  Future<MarkChatConversationReadResponse> markRead(
    String conversationId,
    MarkChatConversationReadPayload payload,
  ) {
    return _apiClient.post<MarkChatConversationReadResponse>(
      ApiEndpoints.chatConversationRead(conversationId),
      data: payload.toJson(),
      requestOptions: _withToken,
      decoder: MarkChatConversationReadResponse.fromJson,
    );
  }
}
