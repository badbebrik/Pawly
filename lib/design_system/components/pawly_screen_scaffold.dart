import 'package:flutter/material.dart';

import '../tokens/pawly_spacing.dart';
import 'pawly_top_bar.dart';

class PawlyScreenScaffold extends StatelessWidget {
  const PawlyScreenScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.appBar,
    this.actions,
    this.leading,
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
  }) : assert(title == null || titleWidget == null);

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final PreferredSizeWidget? appBar;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? pawlyGroupedBackground(context),
      appBar: appBar ??
          PawlyTopBar(
            title: title,
            titleWidget: titleWidget,
            leading: leading,
            actions: actions,
            onBack: onBack,
            automaticallyImplyLeading: automaticallyImplyLeading,
          ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

class PawlyScreenPadding extends StatelessWidget {
  const PawlyScreenPadding({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      PawlySpacing.md,
      PawlySpacing.sm,
      PawlySpacing.md,
      PawlySpacing.xl,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}

Color pawlyGroupedBackground(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    colorScheme.outlineVariant.withValues(alpha: 0.32),
    colorScheme.surface,
  );
}
