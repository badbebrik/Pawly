import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../chat/controllers/chat_direct_conversation_controller.dart';

Future<void> openAclDirectChat({
  required BuildContext context,
  required WidgetRef ref,
  required String petId,
  required String otherUserId,
}) async {
  try {
    final conversationId = await ref
        .read(chatDirectConversationControllerProvider)
        .open(petId: petId, otherUserId: otherUserId);
    if (!context.mounted) {
      return;
    }

    context.pushNamed(
      'chatConversation',
      pathParameters: <String, String>{'conversationId': conversationId},
    );
  } catch (_) {
    if (!context.mounted) {
      return;
    }

    showPawlySnackBar(
      context,
      message: 'Не удалось открыть чат.',
      tone: PawlySnackBarTone.error,
    );
  }
}
