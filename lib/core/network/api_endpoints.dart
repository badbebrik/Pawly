class ApiEndpoints {
  const ApiEndpoints._();

  static const String authRegisterEmail = '/auth/register/email';
  static const String authVerifyEmail = '/auth/verify/email';
  static const String authLoginEmail = '/auth/login/email';
  static const String authLoginOAuth = '/auth/login/oauth';
  static const String authLogout = '/auth/logout';
  static const String authLogoutAll = '/auth/logout-all';
  static const String authRefresh = '/auth/refresh';
  static const String authPasswordResetRequest = '/auth/password/reset/request';
  static const String authPasswordResetVerify = '/auth/password/reset/verify';
  static const String authPasswordResetConfirm = '/auth/password/reset/confirm';

  static const String profileMe = '/v1/profile/me';
  static const String profileAvatarInitUpload =
      '/v1/profile/me/avatar:init-upload';
  static const String profileAvatarConfirmUpload =
      '/v1/profile/me/avatar:confirm-upload';
  static const String profileAvatarTestUpload =
      '/v1/profile/me/avatar:test-upload';

  static const String pets = '/v1/pets';

  static String petById(String petId) => '/v1/pets/$petId';

  static String petStatus(String petId) => '/v1/pets/$petId/status';

  static String petPhotoInitUpload(String petId) =>
      '/v1/pets/$petId/photo:init-upload';

  static String petPhotoConfirmUpload(String petId) =>
      '/v1/pets/$petId/photo:confirm-upload';

  static const String aclPresets = '/v1/acl/presets';

  static String aclBootstrap(String petId) => '/v1/pets/$petId/acl/bootstrap';

  static String aclMe(String petId) => '/v1/pets/$petId/acl/me';

  static String aclMembers(String petId) => '/v1/pets/$petId/acl/members';

  static String aclMemberById(String petId, String memberId) =>
      '/v1/pets/$petId/acl/members/$memberId';

  static String aclRoles(String petId) => '/v1/pets/$petId/acl/roles';

  static String aclRoleById(String petId, String roleId) =>
      '/v1/pets/$petId/acl/roles/$roleId';

  static String aclInvites(String petId) => '/v1/pets/$petId/acl/invites';

  static String aclInviteById(String petId, String inviteId) =>
      '/v1/pets/$petId/acl/invites/$inviteId';

  static const String aclPreviewInviteByToken =
      '/v1/acl/invites/preview-by-token';
  static const String aclAcceptInviteByCode = '/v1/acl/invites/accept-by-code';
  static const String aclAcceptInviteByToken =
      '/v1/acl/invites/accept-by-token';

  static const String catalogVersion = '/catalog/version';
  static const String catalogSpecies = '/catalog/species';
  static const String catalogBreeds = '/catalog/breeds';
  static const String catalogColors = '/catalog/colors';
  static const String catalogPatterns = '/catalog/patterns';
}
