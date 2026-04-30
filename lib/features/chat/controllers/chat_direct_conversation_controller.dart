import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_models.dart';
import 'chat_dependencies.dart';

final chatDirectConversationControllerProvider =
    Provider<ChatDirectConversationController>((ref) {
  return ChatDirectConversationController(ref);
});

class ChatDirectConversationController {
  const ChatDirectConversationController(this._ref);

  final Ref _ref;

  Future<String> open({
    required String petId,
    required String otherUserId,
  }) async {
    final conversation =
        await _ref.read(chatRepositoryProvider).openConversation(
              OpenDirectChatInput(petId: petId, otherUserId: otherUserId),
            );
    return conversation.conversationId;
  }
}
