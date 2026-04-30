import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/acl_permission.dart';
import '../formatters/acl_permission_formatters.dart';

class AclReadOnlyPermissionsList extends StatelessWidget {
  const AclReadOnlyPermissionsList({required this.draft, super.key});

  final AclPermissionDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: draft.items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.42,
              ),
              borderRadius: BorderRadius.circular(PawlyRadius.lg),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.64),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(PawlySpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      aclPermissionDomainLabel(item.domain),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: PawlySpacing.sm),
                  Flexible(
                    child: Text(
                      aclPermissionSummaryLabel(item),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
