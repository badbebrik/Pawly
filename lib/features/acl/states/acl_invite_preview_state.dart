import '../models/acl_invite_preview.dart';

class AclInvitePreviewState {
  const AclInvitePreviewState({
    required this.preview,
    required this.isSubmitting,
  });

  factory AclInvitePreviewState.initial({
    required AclInvitePreview preview,
  }) {
    return AclInvitePreviewState(
      preview: preview,
      isSubmitting: false,
    );
  }

  final AclInvitePreview preview;
  final bool isSubmitting;

  AclInvitePreviewState copyWith({
    AclInvitePreview? preview,
    bool? isSubmitting,
  }) {
    return AclInvitePreviewState(
      preview: preview ?? this.preview,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
