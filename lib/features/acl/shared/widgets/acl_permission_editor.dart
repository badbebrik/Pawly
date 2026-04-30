import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/acl_permission.dart';
import '../formatters/acl_permission_formatters.dart';

class AclPermissionEditor extends StatelessWidget {
  const AclPermissionEditor({
    required this.draft,
    required this.isEnabled,
    required this.onReadChanged,
    required this.onWriteChanged,
    super.key,
  });

  final AclPermissionDraft draft;
  final bool isEnabled;
  final void Function(AclPermissionDomain domain, bool value) onReadChanged;
  final void Function(AclPermissionDomain domain, bool value) onWriteChanged;

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
                  _AclPermissionSwitch(
                    label: 'Просмотр',
                    value: item.canRead,
                    onChanged: isEnabled
                        ? (value) => onReadChanged(item.domain, value)
                        : null,
                  ),
                  const SizedBox(width: PawlySpacing.sm),
                  _AclPermissionSwitch(
                    label: 'Изменение',
                    value: item.canWrite,
                    onChanged: isEnabled
                        ? (value) => onWriteChanged(item.domain, value)
                        : null,
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

class _AclPermissionSwitch extends StatelessWidget {
  const _AclPermissionSwitch({
    required this.label,
    required this.value,
    this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PawlySpacing.xxs),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
