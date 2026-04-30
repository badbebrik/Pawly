import '../../models/acl_role_option.dart';

String aclRoleTitleFromValues({
  required String? code,
  required String title,
}) {
  return switch (code) {
    'OWNER' => 'Владелец',
    'CO_OWNER' => 'Совладелец',
    'VET' => 'Ветеринар',
    'PETSITTER' => 'Петситтер',
    'WALKER' => 'Выгул',
    _ => title,
  };
}

String aclRoleOptionTitle(AclRoleOption role) {
  return aclRoleTitleFromValues(code: role.code, title: role.title);
}
