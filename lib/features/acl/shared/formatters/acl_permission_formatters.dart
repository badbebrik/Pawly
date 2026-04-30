import '../../models/acl_permission.dart';

String aclPermissionDomainLabel(AclPermissionDomain domain) {
  return switch (domain) {
    AclPermissionDomain.pet => 'Питомец',
    AclPermissionDomain.log => 'Журнал',
    AclPermissionDomain.health => 'Здоровье',
    AclPermissionDomain.members => 'Совместный доступ',
  };
}

String aclPermissionSummaryLabel(AclPermissionSelection item) {
  if (item.canWrite) {
    return 'Просмотр и изменение';
  }
  if (item.canRead) {
    return 'Только просмотр';
  }
  return 'Нет доступа';
}
