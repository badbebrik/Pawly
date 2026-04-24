import 'package:flutter/material.dart';

import '../tokens/pawly_radius.dart';
import '../tokens/pawly_spacing.dart';
import 'pawly_screen_scaffold.dart';
import 'pawly_top_bar.dart';

class PawlyFormScaffold extends StatelessWidget {
  const PawlyFormScaffold({
    super.key,
    required this.child,
    this.title,
    this.showAppBar = true,
    this.onBack,
    this.backEnabled = true,
    this.padding = const EdgeInsets.fromLTRB(
      PawlySpacing.md,
      PawlySpacing.sm,
      PawlySpacing.md,
      PawlySpacing.xl,
    ),
  });

  final Widget child;
  final String? title;
  final bool showAppBar;
  final VoidCallback? onBack;
  final bool backEnabled;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return PawlyScreenScaffold(
      title: title,
      appBar: showAppBar
          ? PawlyTopBar(
              title: title,
              onBack: onBack,
              leading: backEnabled
                  ? null
                  : IconButton(
                      onPressed: null,
                      icon: const Icon(Icons.chevron_left_rounded, size: 30),
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                    ),
            )
          : const PreferredSize(
              preferredSize: Size.zero,
              child: SizedBox.shrink(),
            ),
      body: SafeArea(
        top: !showAppBar,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class PawlyPageHeader extends StatelessWidget {
  const PawlyPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
  });

  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(PawlyRadius.lg),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(height: PawlySpacing.md),
        ],
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class PawlyFormCard extends StatelessWidget {
  const PawlyFormCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PawlySpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.82),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PawlyBrandHeader extends StatelessWidget {
  const PawlyBrandHeader({
    super.key,
    this.title = 'Pawly',
    this.subtitle = 'Питомцы и забота рядом',
    this.icon = Icons.pets_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: colorScheme.onPrimary,
            size: 28,
          ),
        ),
        const SizedBox(width: PawlySpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PawlyInlineAction extends StatelessWidget {
  const PawlyInlineAction({
    super.key,
    required this.text,
    required this.actionLabel,
    required this.onPressed,
  });

  final String text;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
