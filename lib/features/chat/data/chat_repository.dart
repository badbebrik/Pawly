import '../../../core/network/clients/chat_api_client.dart';

class ChatRepository {
  ChatRepository({required ChatApiClient chatApiClient})
      : _chatApiClient = chatApiClient;

  final ChatApiClient _chatApiClient;

  ChatApiClient get apiClient => _chatApiClient;
}
