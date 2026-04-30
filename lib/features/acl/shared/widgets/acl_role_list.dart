import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/acl_role_option.dart';
import '../formatters/acl_role_formatters.dart';
import 'acl_role_pill.dart';

class AclRoleList extends StatelessWidget {
  const AclRoleList({
    required this.roles,
    required this.selectedRoleId,
    required this.isEnabled,
    required this.onRoleSelected,
    super.key,
  });

  final List<AclRoleOption> roles;
  final String? selectedRoleId;
  final bool isEnabled;
  final ValueChanged<String?> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: PawlySpacing.xs,
      runSpacing: PawlySpacing.xs,
      children: roles.map((role) {
        return AclRolePill(
          label: aclRoleOptionTitle(role),
          isSelected: selectedRoleId == role.id,
          isEnabled: isEnabled,
          onTap: () => onRoleSelected(role.id),
        );
      }).toList(growable: false),
    );
  }
}
