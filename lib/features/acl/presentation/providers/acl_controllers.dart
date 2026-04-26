import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/acl_models.dart';
import '../../../../core/network/models/pet_models.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../data/acl_repository.dart';
import '../../data/acl_repository_models.dart';
import '../models/acl_screen_models.dart';

final aclRepositoryProvider = Provider<AclRepository>((ref) {
  final aclApiClient = ref.watch(aclApiClientProvider);
  return AclRepository(aclApiClient: aclApiClient);
});

final aclAccessControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AclAccessController, AclAccessScreenState, String>(
  AclAccessController.new,
);

final aclCreateInviteControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AclCreateInviteController, AclCreateInviteState, String>(
  AclCreateInviteController.new,
);

final aclInviteDetailsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AclInviteDetailsController, AclInviteDetailsState, AclInviteRef>(
  AclInviteDetailsController.new,
);

final aclInvitePreviewControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AclInvitePreviewController, AclInvitePreviewState, String>(
  AclInvitePreviewController.new,
);

class AclAccessController extends AsyncNotifier<AclAccessScreenState> {
  AclAccessController(this._petId);

  final String _petId;

  @override
  Future<AclAccessScreenState> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<AclMember> updateMember({
    required String memberId,
    required String roleId,
    required AclPolicy policy,
    String? basePresetId,
  }) async {
    final member = await ref.read(aclRepositoryProvider).updateMember(
          petId: _petId,
          memberId: memberId,
          roleId: roleId,
          basePresetId: basePresetId,
          policy: policy,
        );
    await reload();
    return member;
  }

  Future<void> removeMember(String memberId) async {
    await ref.read(aclRepositoryProvider).removeMember(
          petId: _petId,
          memberId: memberId,
        );
    await reload();
  }

  Future<void> leaveMyAccess() async {
    await ref.read(aclRepositoryProvider).leaveMyAccess(
          petId: _petId,
        );
  }

  Future<void> revokeInvite(String inviteId) async {
    await ref.read(aclRepositoryProvider).revokeInvite(
          petId: _petId,
          inviteId: inviteId,
        );
    await reload();
  }

  Future<Pet> transferOwnership({
    required String targetMemberId,
  }) async {
    final pet = await ref.read(petsRepositoryProvider).getPetById(_petId);
    final updatedPet = await ref.read(petsRepositoryProvider).transferOwnership(
          petId: _petId,
          rowVersion: pet.rowVersion,
          targetMemberId: targetMemberId,
        );
    await reload();
    return updatedPet;
  }

  Future<AclAccessScreenState> _load() async {
    final bootstrap =
        await ref.read(aclRepositoryProvider).getBootstrap(_petId);
    return AclAccessScreenState.fromBootstrap(bootstrap);
  }
}

class AclCreateInviteController extends AsyncNotifier<AclCreateInviteState> {
  AclCreateInviteController(this._petId);

  final String _petId;

  @override
  Future<AclCreateInviteState> build() async {
    final bootstrap =
        await ref.read(aclRepositoryProvider).getBootstrap(_petId);
    return AclCreateInviteState.initial(
      petId: _petId,
      roles: bootstrap.roles,
      presets: bootstrap.presets,
      policy: _defaultPolicy(bootstrap.presets),
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  void selectRole(String? roleId) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final role = current.roleById(roleId);
    final preset = role == null ? null : current.presetForRole(role);

    state = AsyncData(
      current.copyWith(
        selectedRoleId: roleId,
        customRoleTitle: '',
        selectedPresetId: preset?.id,
        permissions: role == null
            ? current.permissions
            : AclPermissionDraft.fromPolicy(role.policy),
      ),
    );
  }

  void setCustomRoleTitle(String value) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        selectedRoleId: null,
        customRoleTitle: value,
        selectedPresetId: null,
      ),
    );
  }

  void selectPreset(String? presetId) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    AclPreset? preset;
    for (final item in current.presets) {
      if (item.id == presetId) {
        preset = item;
        break;
      }
    }

    state = AsyncData(
      current.copyWith(
        selectedPresetId: presetId,
        permissions: preset == null
            ? current.permissions
            : AclPermissionDraft.fromPolicy(preset.policy),
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

  Future<AclCreateInviteResult> submit() async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Экран приглашения еще не готов.');
    }
    if (!current.isRoleSelectionValid) {
      throw StateError(
          'Нужно выбрать существующую роль или ввести название новой.');
    }

    state = AsyncData(current.copyWith(isSubmitting: true));

    try {
      final result = await ref.read(aclRepositoryProvider).createInvite(
            AclCreateInviteInput(
              petId: _petId,
              roleId: current.selectedRoleId,
              customRoleTitle: current.normalizedCustomRoleTitle,
              basePresetId: current.selectedPresetId,
              policy: current.policy,
            ),
          );
      ref.invalidate(aclAccessControllerProvider(_petId));
      state = AsyncData(current.copyWith(isSubmitting: false));
      return result;
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  AclPolicy _defaultPolicy(List<AclPreset> presets) {
    if (presets.isNotEmpty) {
      return presets.first.policy;
    }

    return AclPolicy(
      permissions: <String, bool>{
        for (final domain in AclPermissionDomain.values) ...<String, bool>{
          domain.readKey: false,
          domain.writeKey: false,
        },
      },
    );
  }

  Future<AclCreateInviteState> _load() async {
    final bootstrap =
        await ref.read(aclRepositoryProvider).getBootstrap(_petId);
    return AclCreateInviteState.initial(
      petId: _petId,
      roles: bootstrap.roles,
      presets: bootstrap.presets,
      policy: _defaultPolicy(bootstrap.presets),
    );
  }
}

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

    return AclInviteDetailsState(
      petId: _inviteRef.petId,
      invite: invite,
    );
  }
}

class AclInvitePreviewController extends AsyncNotifier<AclInvitePreviewState> {
  AclInvitePreviewController(this._token);

  final String _token;

  @override
  Future<AclInvitePreviewState> build() async {
    final preview = await ref.read(aclRepositoryProvider).previewInviteByToken(
          _token,
        );
    return AclInvitePreviewState.initial(
      invite: preview.invite,
      pet: preview.pet,
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<AcceptInviteResponse> accept() async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Приглашение еще не загружено.');
    }

    state = AsyncData(current.copyWith(isSubmitting: true));

    try {
      final response =
          await ref.read(aclRepositoryProvider).acceptInviteByToken(
                _token,
              );
      state = AsyncData(current.copyWith(isSubmitting: false));
      return response;
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<AclInvitePreviewState> _load() async {
    final preview = await ref.read(aclRepositoryProvider).previewInviteByToken(
          _token,
        );
    return AclInvitePreviewState.initial(
      invite: preview.invite,
      pet: preview.pet,
    );
  }
}

class AclInviteRef {
  const AclInviteRef({
    required this.petId,
    required this.inviteId,
  });

  final String petId;
  final String inviteId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AclInviteRef &&
        other.petId == petId &&
        other.inviteId == inviteId;
  }

  @override
  int get hashCode => Object.hash(petId, inviteId);
}
