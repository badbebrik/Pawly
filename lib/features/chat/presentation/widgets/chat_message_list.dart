import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../shared/formatters/chat_date_formatters.dart';
import '../../states/chat_conversation_state.dart';
import 'chat_message_bubble.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    required this.state,
    required this.scrollController,
    required this.onLoadOlder,
    super.key,
  });

  final ChatConversationState state;
  final ScrollController scrollController;
  final VoidCallback onLoadOlder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.md,
        PawlySpacing.md,
        PawlySpacing.md,
      ),
      children: <Widget>[
        if (state.hasMoreMessages)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: PawlySpacing.md,
              ),
              child: _LoadOlderButton(
                isLoading: state.isLoadingMoreMessages,
                onPressed: state.isLoadingMoreMessages ? null : onLoadOlder,
              ),
            ),
          ),
        if (state.messages.isEmpty)
          const _EmptyConversationState()
        else
          ..._buildMessageGroups(state),
      ],
    );
  }

  List<Widget> _buildMessageGroups(ChatConversationState state) {
    final widgets = <Widget>[];
    DateTime? previousDay;

    for (final message in state.messages) {
      final createdAt = message.createdAt?.toLocal();
      final messageDay = createdAt == null
          ? null
          : DateTime(createdAt.year, createdAt.month, createdAt.day);

      if (messageDay != null && previousDay != messageDay) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PawlySpacing.md),
            child: Center(
              child: _DateSeparator(
                label: chatMessageDateLabel(messageDay),
              ),
            ),
          ),
        );
        previousDay = messageDay;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
          child: ChatMessageBubble(
            text: message.text,
            timeLabel: chatMessageTimeLabel(createdAt),
            isMine: message.senderUserId == state.currentUserId,
            isSending: message.isSending,
            hasFailed: message.hasFailed,
            isReadByPeer: state.isMessageReadByPeer(message.messageId),
          ),
        ),
      );
    }

    return widgets;
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.sm,
        vertical: PawlySpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _LoadOlderButton extends StatelessWidget {
  const _LoadOlderButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
        foregroundColor: colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.md,
          vertical: PawlySpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.pill),
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
      label: Text(
        isLoading ? 'Загружаем' : 'Ранее',
        style: theme.textTheme.labelLarge,
      ),
    );
  }
}

class _EmptyConversationState extends StatelessWidget {
  const _EmptyConversationState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: PawlySpacing.xl),
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            PawlySpacing.lg,
            PawlySpacing.lg,
            PawlySpacing.lg,
            PawlySpacing.lg,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
          ),
          child: Text(
            'Сообщений пока нет',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
