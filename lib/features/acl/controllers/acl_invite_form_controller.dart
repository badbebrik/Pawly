import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/models/acl_models.dart' as network;
import '../data/acl_repository_models.dart';
import '../models/acl_invite_form_params.dart';
import '../models/acl_permission.dart';
import '../models/acl_role_option.dart';
import '../shared/mappers/acl_permission_mapper.dart';
import '../shared/mappers/acl_role_option_mapper.dart';
import '../states/acl_invite_form_state.dart';
import 'acl_access_controller.dart';
import 'acl_dependencies.dart';

final aclInviteFormControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AclInviteFormController, AclInviteFormState, AclInviteFormParams>(
  AclInviteFormController.new,
);

class AclInviteFormController extends AsyncNotifier<AclInviteFormState> {
  AclInviteFormController(this._params);

  final AclInviteFormParams _params;
  String get _petId => _params.petId;

  @override
  Future<AclInviteFormState> build() async {
    return _load();
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
        permissions: role == null ? current.permissions : role.permissions,
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

    AclPresetOption? preset;
    for (final item in current.presets) {
      if (item.id == presetId) {
        preset = item;
        break;
      }
    }

    state = AsyncData(
      current.copyWith(
        selectedPresetId: presetId,
        permissions: preset == null ? current.permissions : preset.permissions,
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
      final repository = ref.read(aclRepositoryProvider);
      final result = await repository.createInvite(
        AclCreateInviteInput(
          petId: _petId,
          roleId: current.selectedRoleId,
          customRoleTitle: current.normalizedCustomRoleTitle,
          basePresetId: current.selectedPresetId,
          policy: aclPermissionDraftToNetwork(current.permissions),
        ),
      );
      final inviteId = current.inviteId;
      if (inviteId != null && inviteId.isNotEmpty) {
        await repository.revokeInvite(
          petId: _petId,
          inviteId: inviteId,
        );
      }
      ref.invalidate(aclAccessControllerProvider(_petId));
      state = AsyncData(current.copyWith(isSubmitting: false));
      return result;
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  AclPermissionDraft _defaultPermissions(List<AclPresetOption> presets) {
    if (presets.isNotEmpty) {
      return presets.first.permissions;
    }

    return AclPermissionDraft(
      items: AclPermissionDomain.values.map((domain) {
        return AclPermissionSelection(
          domain: domain,
          canRead: false,
          canWrite: false,
        );
      }).toList(growable: false),
    );
  }

  Future<AclInviteFormState> _load() async {
    final bootstrap =
        await ref.read(aclRepositoryProvider).getBootstrap(_petId);
    final roles = bootstrap.roles.map(aclRoleOptionFromNetwork).toList(
          growable: false,
        );
    final presets = bootstrap.presets.map(aclPresetOptionFromNetwork).toList(
          growable: false,
        );
    if (_params.isEditMode) {
      final invite = _inviteById(bootstrap.invites, _params.inviteId!);
      if (invite == null) {
        throw StateError('Приглашение не найдено.');
      }

      var permissions = aclPermissionDraftFromNetwork(invite.policy);
      final basePresetId = invite.basePresetId;
      if (basePresetId != null && basePresetId.isNotEmpty) {
        final preset = _presetById(presets, basePresetId);
        permissions = preset?.permissions ?? permissions;
      }

      return AclInviteFormState.initial(
        petId: _petId,
        inviteId: invite.id,
        roles: roles,
        presets: presets,
        selectedRoleId: invite.role.id,
        selectedPresetId: invite.basePresetId,
        permissions: permissions,
      );
    }

    return AclInviteFormState.initial(
      petId: _petId,
      roles: roles,
      presets: presets,
      permissions: _defaultPermissions(presets),
    );
  }
}

network.AclInvite? _inviteById(
  List<network.AclInvite> invites,
  String inviteId,
) {
  for (final invite in invites) {
    if (invite.id == inviteId) {
      return invite;
    }
  }
  return null;
}

AclPresetOption? _presetById(List<AclPresetOption> presets, String presetId) {
  for (final preset in presets) {
    if (preset.id == presetId) {
      return preset;
    }
  }
  return null;
}
