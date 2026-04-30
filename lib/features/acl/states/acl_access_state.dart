import '../models/acl_access.dart';
import '../models/acl_member.dart';

class AclAccessState {
  const AclAccessState({
    required this.petId,
    required this.me,
    required this.capabilities,
    required this.members,
    required this.invites,
  });

  final String petId;
  final AclMember me;
  final AclAccessCapabilities capabilities;
  final List<AclMember> members;
  final List<AclAccessInvite> invites;

  List<AclMember> get activeMembers {
    return members.where((member) => member.isActive).toList(growable: false);
  }

  List<AclMember> get membersForDisplay {
    final owners = <AclMember>[];
    final others = <AclMember>[];

    for (final member in activeMembers) {
      if (member.isPrimaryOwner) {
        owners.add(member);
      } else {
        others.add(member);
      }
    }

    return <AclMember>[...owners, ...others];
  }

  List<AclAccessInvite> get activeInvites {
    return invites.where((invite) => invite.isActive).toList(growable: false);
  }

  AclAccessState copyWith({
    AclMember? me,
    AclAccessCapabilities? capabilities,
    List<AclMember>? members,
    List<AclAccessInvite>? invites,
  }) {
    return AclAccessState(
      petId: petId,
      me: me ?? this.me,
      capabilities: capabilities ?? this.capabilities,
      members: members ?? this.members,
      invites: invites ?? this.invites,
    );
  }
}
