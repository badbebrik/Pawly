class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String postRegisterChoice = '/auth/post-register-choice';
  static const String passwordResetRequest = '/auth/password-reset';
  static const String passwordResetVerify = '/auth/password-reset/verify';
  static const String passwordResetConfirm = '/auth/password-reset/confirm';
  static const String home = '/home';
  static const String calendar = '/home/calendar';
  static const String pets = '/home/pets';
  static const String settings = '/home/settings';
  static const String petCreate = '/pets/create';
  static const String aclInvitePreview = '/invite-preview';
}
