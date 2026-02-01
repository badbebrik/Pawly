import 'package:flutter/material.dart';

import '../tokens/pawly_radius.dart';
import '../tokens/pawly_spacing.dart';

class PawlyCard extends StatelessWidget {
  const PawlyCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.footer,
    this.onTap,
    this.padding = const EdgeInsets.all(PawlySpacing.md),
  });

  final Widget child;
  final Widget? title;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null || trailing != null)
            Padding(
              padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
              child: Row(
                children: <Widget>[
                  if (title != null) Expanded(child: title!),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          child,
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: PawlySpacing.md),
              child: footer!,
            ),
        ],
      ),
    );

    if (onTap == null) {
      return Card(child: content);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: content,
      ),
    );
  }
}
