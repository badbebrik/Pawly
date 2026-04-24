import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../chat/presentation/providers/chat_providers.dart';

class ChatAppBarAction extends ConsumerWidget {
  const ChatAppBarAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadState = ref.watch(chatUnreadSummaryControllerProvider);
    final unreadCount = unreadState.asData?.value.unreadConversations ?? 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Tooltip(
        message: 'Сообщения',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.pushNamed('chatInbox'),
            customBorder: const CircleBorder(),
            child: Ink(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(
                    CupertinoIcons.chat_bubble_text,
                    color: colorScheme.onSurface,
                    size: 22,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onError,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
