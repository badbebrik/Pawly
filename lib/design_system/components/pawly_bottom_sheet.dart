import 'package:flutter/material.dart';

import '../tokens/pawly_colors.dart';
import '../tokens/pawly_radius.dart';
import '../tokens/pawly_spacing.dart';

Future<T?> showPawlyBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (context) => PawlyBottomSheet(
      title: title,
      child: builder(context),
    ),
  );
}

class PawlyBottomSheet extends StatelessWidget {
  const PawlyBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.footer,
    this.padding = const EdgeInsets.fromLTRB(
      PawlySpacing.lg,
      PawlySpacing.sm,
      PawlySpacing.lg,
      PawlySpacing.lg,
    ),
  });

  final String? title;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(PawlyRadius.xl),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 38,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorScheme.brightness == Brightness.dark
                            ? colorScheme.outline
                            : PawlyColors.gray300,
                        borderRadius: BorderRadius.circular(PawlyRadius.pill),
                      ),
                    ),
                  ),
                  if (title != null) ...<Widget>[
                    const SizedBox(height: PawlySpacing.md),
                    Text(
                      title!,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: PawlySpacing.md),
                  Flexible(
                    child: SingleChildScrollView(child: child),
                  ),
                  if (footer != null) ...<Widget>[
                    const SizedBox(height: PawlySpacing.lg),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
