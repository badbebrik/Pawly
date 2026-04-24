import 'package:flutter/material.dart';

class PawlyTopBar extends StatelessWidget implements PreferredSizeWidget {
  const PawlyTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.backgroundColor = Colors.transparent,
  }) : assert(title == null || titleWidget == null);

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final Color backgroundColor;

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: titleWidget ?? (title == null ? null : Text(title!)),
      leading: leading ?? _buildBackButton(context),
      actions: actions,
      bottom: bottom,
    );
  }

  Widget? _buildBackButton(BuildContext context) {
    if (!automaticallyImplyLeading || !Navigator.of(context).canPop()) {
      return null;
    }

    return IconButton(
      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.chevron_left_rounded, size: 30),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
