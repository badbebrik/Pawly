import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/models/acl_models.dart' as network;
import '../../pets/controllers/pets_controller.dart';
import '../models/acl_access.dart';
import '../models/acl_member_details_params.dart';
import '../models/acl_permission.dart';
import '../shared/mappers/acl_member_mapper.dart';
import '../shared/mappers/acl_permission_mapper.dart';
import '../shared/mappers/acl_role_option_mapper.dart';
import '../states/acl_member_details_state.dart';
import 'acl_access_controller.dart';
import 'acl_dependencies.dart';

final aclMemberDetailsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AclMemberDetailsController, AclMemberDetailsState,
        AclMemberDetailsParams>(
  AclMemberDetailsController.new,
);

class AclMemberDetailsController extends AsyncNotifier<AclMemberDetailsState> {
  AclMemberDetailsController(this._params);

  final AclMemberDetailsParams _params;

  String get _petId => _params.petId;

  @override
  Future<AclMemberDetailsState> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  void selectRole(String? roleId) {
    final current = state.asData?.value;
    if (current == null || roleId == null) {
      return;
    }

    final role = current.roleById(roleId);
    final preset = role == null ? null : current.presetForRole(role);
    state = AsyncData(
      current.copyWith(
        selectedRoleId: roleId,
        selectedPresetId: preset?.id,
        permissions: role == null ? current.permissions : role.permissions,
      ),
    );
  }

  void setReadPermission(AclPermissionDomain domain, bool value) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        selectedPresetId: null,
        permissions: current.permissions.updateRead(domain, value),
      ),
    );
  }

  void setWritePermission(AclPermissionDomain domain, bool value) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        selectedPresetId: null,
        permissions: current.permissions.updateWrite(domain, value),
      ),
    );
  }

  Future<void> saveChanges() async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Экран участника еще не готов.');
    }
    if (current.member.userId == current.me.userId) {
      throw StateError('Себе нельзя менять роль и права.');
    }

    final selectedRoleId = current.selectedRoleId;
    if (selectedRoleId == null || selectedRoleId.isEmpty) {
      throw StateError('Выберите роль участника.');
    }

    state = AsyncData(current.copyWith(isSubmitting: true));

    try {
      await ref.read(aclRepositoryProvider).updateMember(
            petId: _petId,
            memberId: current.member.id,
            roleId: selectedRoleId,
            basePresetId: current.selectedPresetId,
            policy: aclPermissionDraftToNetwork(current.permissions),
          );
      ref.invalidate(aclAccessControllerProvider(_petId));
      state = AsyncData(
        current.copyWith(isSubmitting: false),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<void> revokeAccess() async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Экран участника еще не готов.');
    }

    state = AsyncData(current.copyWith(isSubmitting: true));

    try {
      await ref.read(aclRepositoryProvider).removeMember(
            petId: _petId,
            memberId: current.member.id,
          );
      ref.invalidate(aclAccessControllerProvider(_petId));
      state = AsyncData(current.copyWith(isSubmitting: false));
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<void> leaveAccess() async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Экран участника еще не готов.');
    }

    state = AsyncData(current.copyWith(isSubmitting: true));

    try {
      await ref.read(aclRepositoryProvider).leaveMyAccess(petId: _petId);
      ref.invalidate(aclAccessControllerProvider(_petId));
      state = AsyncData(current.copyWith(isSubmitting: false));
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<void> transferOwnership() async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Экран участника еще не готов.');
    }

    state = AsyncData(current.copyWith(isSubmitting: true));

    try {
      final pet = await ref.read(petsRepositoryProvider).getPetById(_petId);
      await ref.read(petsRepositoryProvider).transferOwnership(
            petId: _petId,
            rowVersion: pet.rowVersion,
            targetMemberId: current.member.id,
          );
      ref.invalidate(aclAccessControllerProvider(_petId));
      state = AsyncData(current.copyWith(isSubmitting: false));
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<AclMemberDetailsState> _load() async {
    final bootstrap =
        await ref.read(aclRepositoryProvider).getBootstrap(_petId);
    network.AclMember? member;
    for (final item in bootstrap.members) {
      if (item.id == _params.memberId) {
        member = item;
        break;
      }
    }

    if (member == null) {
      throw StateError('Участник не найден.');
    }

    final roles = bootstrap.roles.map(aclRoleOptionFromNetwork).toList(
          growable: false,
        );
    final presets = bootstrap.presets.map(aclPresetOptionFromNetwork).toList(
          growable: false,
        );

    return AclMemberDetailsState.initial(
      petId: _petId,
      me: aclMemberFromNetwork(bootstrap.me),
      capabilities: AclAccessCapabilities(
        membersRead: bootstrap.capabilities.membersRead,
        membersWrite: bootstrap.capabilities.membersWrite,
      ),
      member: aclMemberFromNetwork(member),
      roles: roles,
      presets: presets,
    );
  }
}
