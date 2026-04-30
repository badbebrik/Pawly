import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../states/chat_conversation_state.dart';
import 'chat_avatar.dart';

class ChatConversationHeader extends StatelessWidget {
  const ChatConversationHeader({
    required this.state,
    super.key,
  });

  final ChatConversationState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        ChatAvatar(
          userId: state.conversation.peer.userId,
          displayName: state.conversation.peer.displayName,
          avatarUrl: state.conversation.peer.avatarUrl,
          size: 38,
        ),
        const SizedBox(width: PawlySpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                state.conversation.peer.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: state.conversation.otherUserInChat
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: PawlySpacing.xxs),
                  Expanded(
                    child: Text(
                      '${state.conversation.otherUserInChat ? 'В чате' : 'Не в чате'} · ${state.conversation.pet.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
