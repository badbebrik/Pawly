import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/models/acl_models.dart';
import '../models/acl_invite_ref.dart';
import '../shared/mappers/acl_invite_details_mapper.dart';
import '../states/acl_invite_details_state.dart';
import 'acl_access_controller.dart';
import 'acl_dependencies.dart';

final aclInviteDetailsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AclInviteDetailsController, AclInviteDetailsState, AclInviteRef>(
  AclInviteDetailsController.new,
);

class AclInviteDetailsController extends AsyncNotifier<AclInviteDetailsState> {
  AclInviteDetailsController(this._inviteRef);

  final AclInviteRef _inviteRef;

  @override
  Future<AclInviteDetailsState> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<void> revokeInvite() async {
    await ref.read(aclRepositoryProvider).revokeInvite(
          petId: _inviteRef.petId,
          inviteId: _inviteRef.inviteId,
        );
    ref.invalidate(aclAccessControllerProvider(_inviteRef.petId));
  }

  Future<AclInviteDetailsState> _load() async {
    final bootstrap =
        await ref.read(aclRepositoryProvider).getBootstrap(_inviteRef.petId);
    AclInvite? invite;
    for (final item in bootstrap.invites) {
      if (item.id == _inviteRef.inviteId) {
        invite = item;
        break;
      }
    }

    if (invite == null) {
      throw StateError('Приглашение не найдено.');
    }

    return AclInviteDetailsState(details: aclInviteDetailsFromNetwork(invite));
  }
}
