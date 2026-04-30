import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.text,
    required this.timeLabel,
    required this.isMine,
    required this.isSending,
    required this.hasFailed,
    required this.isReadByPeer,
    super.key,
  });

  final String text;
  final String timeLabel;
  final bool isMine;
  final bool isSending;
  final bool hasFailed;
  final bool isReadByPeer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bubbleColor = isMine ? colorScheme.primary : colorScheme.surface;
    final foreground = isMine ? colorScheme.onPrimary : colorScheme.onSurface;
    final metaColor = isMine
        ? colorScheme.onPrimary.withValues(alpha: 0.78)
        : colorScheme.onSurfaceVariant;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.76;

    return Row(
      mainAxisAlignment:
          isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(PawlyRadius.xl),
                topRight: const Radius.circular(PawlyRadius.xl),
                bottomLeft: Radius.circular(
                  isMine ? PawlyRadius.xl : PawlyRadius.sm,
                ),
                bottomRight: Radius.circular(
                  isMine ? PawlyRadius.sm : PawlyRadius.xl,
                ),
              ),
              boxShadow: isMine
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                PawlySpacing.md,
                PawlySpacing.sm,
                PawlySpacing.md,
                PawlySpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      height: 1.32,
                    ),
                  ),
                  if (timeLabel.isNotEmpty) ...<Widget>[
                    const SizedBox(height: PawlySpacing.xs),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (hasFailed)
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: PawlySpacing.xs),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 14,
                                color: colorScheme.error,
                              ),
                            ),
                          if (isSending)
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: PawlySpacing.xs),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: metaColor,
                                ),
                              ),
                            ),
                          Text(
                            timeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: hasFailed ? colorScheme.error : metaColor,
                            ),
                          ),
                          if (isMine && !hasFailed && !isSending) ...<Widget>[
                            const SizedBox(width: PawlySpacing.xs),
                            Icon(
                              isReadByPeer
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 14,
                              color: isReadByPeer
                                  ? (isMine
                                      ? colorScheme.onPrimary
                                      : colorScheme.primary)
                                  : metaColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else if (isSending || hasFailed) ...<Widget>[
                    const SizedBox(height: PawlySpacing.xs),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(
                        hasFailed
                            ? Icons.error_outline_rounded
                            : Icons.schedule_rounded,
                        size: 14,
                        color: hasFailed ? colorScheme.error : metaColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
