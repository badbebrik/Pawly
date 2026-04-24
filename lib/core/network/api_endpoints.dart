class ApiEndpoints {
  const ApiEndpoints._();

  static const String authRegisterEmail = '/v1/auth/email:register';
  static const String authVerificationEmailResend =
      '/v1/auth/email-verification:resend';
  static const String authVerifyEmail = '/v1/auth/email-verification:verify';
  static const String authLoginEmail = '/v1/auth/sessions:login-email';
  static const String authLoginOAuth = '/v1/auth/sessions:login-oauth';
  static const String authLogout = '/v1/auth/sessions:revoke';
  static const String authLogoutAll = '/v1/auth/sessions:revoke-all';
  static const String authRefresh = '/v1/auth/sessions:refresh';
  static const String authPasswordResetRequest =
      '/v1/auth/password-reset:request';
  static const String authPasswordResetVerify =
      '/v1/auth/password-reset:verify';
  static const String authPasswordResetConfirm =
      '/v1/auth/password-reset:confirm';
  static const String authPasswordChange = '/v1/auth/password:change';

  static const String profileMe = '/v1/profiles/me';
  static const String profilePreferences = '/v1/profiles/me/preferences';
  static const String profileAvatarInitUpload =
      '/v1/profiles/me/avatar:init-upload';
  static const String profileAvatarConfirmUpload =
      '/v1/profiles/me/avatar:confirm-upload';
  static const String profileAvatar = '/v1/profiles/me/avatar';

  static const String chatConversationsOpen = '/v1/chat/conversations:open';
  static const String chatConversations = '/v1/chat/conversations';
  static const String chatUnreadSummary = '/v1/chat/unread-summary';
  static const String chatWs = '/v1/chat/ws';

  static String chatConversationById(String conversationId) =>
      '/v1/chat/conversations/$conversationId';

  static String chatConversationMessages(String conversationId) =>
      '/v1/chat/conversations/$conversationId/messages';

  static String chatConversationRead(String conversationId) =>
      '/v1/chat/conversations/$conversationId:mark-read';

  static const String pets = '/v1/pets';

  static String petById(String petId) => '/v1/pets/$petId';

  static String petStatus(String petId) => '/v1/pets/$petId:change-status';

  static String petTransferOwnership(String petId) =>
      '/v1/pets/$petId:transfer-ownership';

  static String petPhotoInitUpload(String petId) =>
      '/v1/pets/$petId/photo:init-upload';

  static String petPhotoConfirmUpload(String petId) =>
      '/v1/pets/$petId/photo:confirm-upload';

  static String petPhoto(String petId) => '/v1/pets/$petId/photo';

  static String petLogsBootstrap(String petId) =>
      '/v1/pets/$petId/logs/bootstrap';

  static String petLogs(String petId) => '/v1/pets/$petId/logs';

  static String petLogById(String petId, String logId) =>
      '/v1/pets/$petId/logs/$logId';

  static String petLogTypes(String petId) => '/v1/pets/$petId/log-types';

  static String petLogTypeById(String petId, String logTypeId) =>
      '/v1/pets/$petId/log-types/$logTypeId';

  static String petMetrics(String petId) => '/v1/pets/$petId/metrics';

  static String petMetricById(String petId, String metricId) =>
      '/v1/pets/$petId/metrics/$metricId';

  static String petAnalyticsMetrics(String petId) =>
      '/v1/pets/$petId/analytics/metrics';

  static String petAnalyticsMetricSeries(String petId, String metricId) =>
      '/v1/pets/$petId/analytics/metrics/$metricId/series';

  static String petHealthBootstrap(String petId) =>
      '/v1/pets/$petId/health/bootstrap';

  static const String healthDay = '/v1/health/day';

  static const String healthCalendar = '/v1/health/calendar';

  static String petHealthDay(String petId) => '/v1/pets/$petId/health/day';

  static String petScheduledItems(String petId) =>
      '/v1/pets/$petId/scheduled-items';

  static String petScheduledItemById(String petId, String itemId) =>
      '/v1/pets/$petId/scheduled-items/$itemId';

  static String petScheduledItemReminderSettings(String petId, String itemId) =>
      '/v1/pets/$petId/scheduled-items/$itemId/reminder-settings';

  static String petScheduledItemOccurrences(String petId) =>
      '/v1/pets/$petId/scheduled-item-occurrences';

  static String petScheduledItemOccurrenceById(
    String petId,
    String occurrenceId,
  ) =>
      '/v1/pets/$petId/scheduled-item-occurrences/$occurrenceId';

  static const String pushDevices = '/v1/push/devices';

  static String pushDeviceById(String deviceId) => '/v1/push/devices/$deviceId';

  static String petPushSettings(String petId) =>
      '/v1/pets/$petId/push-settings';

  static String petAttachmentsInitUpload(String petId) =>
      '/v1/pets/$petId/attachments:init-upload';

  static String petAttachmentsConfirmUpload(String petId) =>
      '/v1/pets/$petId/attachments:confirm-upload';

  static String petDocuments(String petId) => '/v1/pets/$petId/documents';

  static String petDocumentById(String petId, String documentId) =>
      '/v1/pets/$petId/documents/$documentId';

  static String petVetVisits(String petId) => '/v1/pets/$petId/vet-visits';

  static String petVetVisitById(String petId, String visitId) =>
      '/v1/pets/$petId/vet-visits/$visitId';

  static String petVetVisitLogs(String petId, String visitId) =>
      '/v1/pets/$petId/vet-visits/$visitId/logs';

  static String petVetVisitLogById(
          String petId, String visitId, String logId) =>
      '/v1/pets/$petId/vet-visits/$visitId/logs/$logId';

  static String petVaccinations(String petId) => '/v1/pets/$petId/vaccinations';

  static String petVaccinationById(String petId, String vaccinationId) =>
      '/v1/pets/$petId/vaccinations/$vaccinationId';

  static String petProcedures(String petId) => '/v1/pets/$petId/procedures';

  static String petProcedureById(String petId, String procedureId) =>
      '/v1/pets/$petId/procedures/$procedureId';

  static String petMedicalRecords(String petId) =>
      '/v1/pets/$petId/medical-records';

  static String petMedicalRecordById(String petId, String recordId) =>
      '/v1/pets/$petId/medical-records/$recordId';

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

  static String aclInviteRegenerateLink(String petId, String inviteId) =>
      '/v1/pets/$petId/acl/invites/$inviteId:regenerate-link';

  static const String aclPreviewInviteByToken =
      '/v1/acl/invites:preview-by-token';
  static const String aclAcceptInviteByCode = '/v1/acl/invites:accept-by-code';
  static const String aclAcceptInviteByToken =
      '/v1/acl/invites:accept-by-token';

  static const String petDictionaries = '/v1/pet-dictionaries';
}
