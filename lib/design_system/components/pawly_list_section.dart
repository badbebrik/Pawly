import 'package:flutter/material.dart';

import '../tokens/pawly_radius.dart';
import '../tokens/pawly_spacing.dart';

class PawlyListSection extends StatelessWidget {
  const PawlyListSection({
    super.key,
    required this.children,
    this.title,
    this.footer,
    this.padding = EdgeInsets.zero,
  });

  final String? title;
  final List<Widget> children;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: PawlySpacing.xs,
              bottom: PawlySpacing.sm,
            ),
            child: Text(
              title!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.82),
            ),
          ),
          child: Padding(
            padding: padding,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PawlyRadius.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _separatedChildren(context),
              ),
            ),
          ),
        ),
        if (footer != null) ...<Widget>[
          const SizedBox(height: PawlySpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PawlySpacing.xs),
            child: footer!,
          ),
        ],
      ],
    );
  }

  List<Widget> _separatedChildren(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final result = <Widget>[];

    for (var index = 0; index < children.length; index += 1) {
      if (index > 0) {
        result.add(
          Divider(
            height: 1,
            indent: PawlySpacing.md,
            color: colorScheme.outlineVariant,
          ),
        );
      }
      result.add(children[index]);
    }

    return result;
  }
}

class PawlyListTile extends StatelessWidget {
  const PawlyListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.leadingIcon,
    this.value,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? leadingIcon;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foregroundColor = !enabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : isDestructive
            ? colorScheme.error
            : colorScheme.onSurface;
    final secondaryColor = !enabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : colorScheme.onSurfaceVariant;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.md,
        vertical: PawlySpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          if (leading != null || leadingIcon != null) ...<Widget>[
            leading ??
                Icon(
                  leadingIcon,
                  color: isDestructive ? colorScheme.error : secondaryColor,
                ),
            const SizedBox(width: PawlySpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.xxxs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...<Widget>[
            const SizedBox(width: PawlySpacing.sm),
            Flexible(
              child: Text(
                value!,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (trailing != null) ...<Widget>[
            const SizedBox(width: PawlySpacing.xs),
            trailing!,
          ] else if (onTap != null) ...<Widget>[
            const SizedBox(width: PawlySpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              color: secondaryColor,
            ),
          ],
        ],
      ),
    );

    if (onTap == null || !enabled) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }
}
