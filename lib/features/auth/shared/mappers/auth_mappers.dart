import '../../../../core/network/models/auth_models.dart';
import '../../models/password_reset_verification.dart';
import '../../models/register_start_result.dart';

RegisterStartResult registerStartResultFromResponse(
  RegisterEmailResponse response,
) {
  return RegisterStartResult(
    canResendInSeconds: response.canResendInSeconds,
  );
}

PasswordResetVerification passwordResetVerificationFromResponse(
  PasswordResetVerifyResponse response,
) {
  return PasswordResetVerification(resetToken: response.resetToken);
}
