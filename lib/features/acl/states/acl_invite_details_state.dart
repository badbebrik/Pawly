import '../models/acl_invite_details.dart';

class AclInviteDetailsState {
  const AclInviteDetailsState({
    required this.details,
  });

  final AclInviteDetails details;

  AclInviteDetailsState copyWith({AclInviteDetails? details}) {
    return AclInviteDetailsState(
      details: details ?? this.details,
    );
  }
}
