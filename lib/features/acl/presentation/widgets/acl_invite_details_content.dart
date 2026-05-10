import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/image_memory_pressure.dart';
import '../../../../design_system/design_system.dart';
import '../../models/acl_invite_details.dart';
import '../../shared/formatters/acl_invite_formatters.dart';
import '../../shared/widgets/acl_form_section.dart';
import '../../shared/widgets/acl_read_only_permissions_list.dart';
import '../../states/acl_invite_details_state.dart';

class AclInviteDetailsContent extends StatelessWidget {
  const AclInviteDetailsContent({required this.state, super.key});

  final AclInviteDetailsState state;

  @override
  Widget build(BuildContext context) {
    final details = state.details;
    final deeplinkUrl = details.deeplinkUrl ?? '';
    final hasLink = deeplinkUrl.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        _InviteSummaryCard(details: details),
        const SizedBox(height: PawlySpacing.md),
        AclFormSection(
          title: 'Ссылка',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _InviteValueTile(
                value: hasLink ? deeplinkUrl : 'Ссылка недоступна',
                isMuted: !hasLink,
                onCopy: hasLink
                    ? () => _copyText(
                        context,
                        deeplinkUrl,
                        'Ссылка приглашения скопирована.',
                      )
                    : null,
              ),
              const SizedBox(height: PawlySpacing.sm),
              PawlyButton(
                label: 'Поделиться ссылкой',
                onPressed: hasLink
                    ? () => _shareLink(context, deeplinkUrl)
                    : null,
                variant: PawlyButtonVariant.secondary,
                icon: Icons.ios_share_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        AclFormSection(
          title: 'Код',
          child: _InviteValueTile(
            value: details.code,
            isCode: true,
            onCopy: () =>
                _copyText(context, details.code, 'Код приглашения скопирован.'),
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        AclFormSection(
          title: 'Права доступа',
          child: AclReadOnlyPermissionsList(draft: details.permissions),
        ),
      ],
    );
  }

  Future<void> _copyText(
    BuildContext context,
    String value,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    showPawlySnackBar(
      context,
      message: message,
      tone: PawlySnackBarTone.neutral,
    );
  }

  Future<void> _shareLink(BuildContext context, String url) async {
    final box = context.findRenderObject() as RenderBox?;
    trimDecodedImageMemory(includeLiveImages: true);
    await SharePlus.instance.share(
      ShareParams(
        text: url,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
    if (!context.mounted) {
      return;
    }
  }
}

class _InviteSummaryCard extends StatelessWidget {
  const _InviteSummaryCard({required this.details});

  final AclInviteDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Доступ по приглашению',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: PawlySpacing.xxs),
            Text(
              'Роль: ${details.roleTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: PawlySpacing.xxs),
            Text(
              aclInviteMetaLabel(details.expiresAt),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteValueTile extends StatelessWidget {
  const _InviteValueTile({
    required this.value,
    this.isCode = false,
    this.isMuted = false,
    this.onCopy,
  });

  final String value;
  final bool isCode;
  final bool isMuted;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.64),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.md,
          vertical: PawlySpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: SelectableText(
                value,
                style:
                    (isCode
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                          color: isMuted
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                          fontWeight: isCode
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            _InviteCopyButton(onPressed: onCopy),
          ],
        ),
      ),
    );
  }
}

class _InviteCopyButton extends StatelessWidget {
  const _InviteCopyButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surface,
        disabledBackgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.36,
        ),
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.md),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.68),
          ),
        ),
      ),
      icon: const Icon(Icons.content_copy_rounded),
      tooltip: 'Копировать',
    );
  }
}
