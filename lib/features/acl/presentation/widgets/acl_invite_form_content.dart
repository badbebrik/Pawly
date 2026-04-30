import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/acl_permission.dart';
import '../../models/acl_role_option.dart';
import '../../shared/formatters/acl_role_formatters.dart';
import '../../shared/widgets/acl_form_section.dart';
import '../../shared/widgets/acl_permission_editor.dart';
import '../../shared/widgets/acl_role_list.dart';

class AclInviteFormContent extends StatelessWidget {
  const AclInviteFormContent({
    required this.title,
    required this.submittingTitle,
    required this.systemRoles,
    required this.customRoles,
    required this.selectedRoleId,
    required this.customRoleTitle,
    required this.customRoleController,
    required this.permissions,
    required this.isSubmitting,
    required this.onRoleSelected,
    required this.onCustomRoleChanged,
    required this.onReadChanged,
    required this.onWriteChanged,
    required this.onSubmit,
    super.key,
  });

  final String title;
  final String submittingTitle;
  final List<AclRoleOption> systemRoles;
  final List<AclRoleOption> customRoles;
  final String? selectedRoleId;
  final String customRoleTitle;
  final TextEditingController customRoleController;
  final AclPermissionDraft permissions;
  final bool isSubmitting;
  final ValueChanged<String?> onRoleSelected;
  final ValueChanged<String> onCustomRoleChanged;
  final void Function(AclPermissionDomain domain, bool value) onReadChanged;
  final void Function(AclPermissionDomain domain, bool value) onWriteChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedRole = _roleById(
      <AclRoleOption>[...systemRoles, ...customRoles],
      selectedRoleId ?? '',
    );
    final normalizedCustomRoleTitle = customRoleTitle.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        AclFormSection(
          title: 'Роль',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (systemRoles.isNotEmpty) ...<Widget>[
                Text(
                  'Системные роли',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                AclRoleList(
                  roles: systemRoles,
                  selectedRoleId: selectedRoleId,
                  isEnabled: !isSubmitting,
                  onRoleSelected: onRoleSelected,
                ),
              ],
              if (customRoles.isNotEmpty) ...<Widget>[
                const SizedBox(height: PawlySpacing.md),
                Text(
                  'Кастомные роли',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                AclRoleList(
                  roles: customRoles,
                  selectedRoleId: selectedRoleId,
                  isEnabled: !isSubmitting,
                  onRoleSelected: onRoleSelected,
                ),
              ],
              const SizedBox(height: PawlySpacing.md),
              PawlyTextField(
                controller: customRoleController,
                label: 'Новая роль',
                hintText: 'Например, Семейный помощник',
                textCapitalization: TextCapitalization.sentences,
                onChanged: onCustomRoleChanged,
                enabled: !isSubmitting,
              ),
              if (selectedRole != null ||
                  normalizedCustomRoleTitle.isNotEmpty) ...<Widget>[
                const SizedBox(height: PawlySpacing.sm),
                Text(
                  selectedRole != null
                      ? 'Выбрана роль: ${aclRoleOptionTitle(selectedRole)}'
                      : 'Новая роль: $normalizedCustomRoleTitle',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        AclFormSection(
          title: 'Права',
          child: AclPermissionEditor(
            draft: permissions,
            isEnabled: !isSubmitting,
            onReadChanged: onReadChanged,
            onWriteChanged: onWriteChanged,
          ),
        ),
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: isSubmitting ? submittingTitle : title,
          onPressed: isSubmitting ? null : onSubmit,
        ),
      ],
    );
  }
}

AclRoleOption? _roleById(List<AclRoleOption> roles, String roleId) {
  for (final role in roles) {
    if (role.id == roleId) {
      return role;
    }
  }
  return null;
}
