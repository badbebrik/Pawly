import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/acl_models.dart';
import '../../../../design_system/design_system.dart';
import '../../data/acl_repository_models.dart';
import '../models/acl_screen_models.dart';
import '../providers/acl_controllers.dart';

class AclInviteFormPage extends ConsumerStatefulWidget {
  const AclInviteFormPage({
    required this.petId,
    this.inviteId,
    super.key,
  });

  final String petId;
  final String? inviteId;

  bool get isEditMode => inviteId != null && inviteId!.isNotEmpty;

  @override
  ConsumerState<AclInviteFormPage> createState() => _AclInviteFormPageState();
}

class _AclInviteFormPageState extends ConsumerState<AclInviteFormPage> {
  late final TextEditingController _customRoleController;
  String? _selectedRoleId;
  String? _selectedPresetId;
  AclPermissionDraft? _permissions;
  bool _isSubmitting = false;
  bool _initializedEditState = false;

  @override
  void initState() {
    super.initState();
    _customRoleController = TextEditingController();
  }

  @override
  void dispose() {
    _customRoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditMode) {
      return _buildEditMode();
    }
    return _buildCreateMode();
  }

  Widget _buildCreateMode() {
    final state = ref.watch(aclCreateInviteControllerProvider(widget.petId));

    return PawlyScreenScaffold(
      title: 'Новое приглашение',
      body: state.when(
        data: (value) {
          _syncCustomRoleController(value.customRoleTitle);

          return _AclInviteFormContent(
            title: 'Создать приглашение',
            submittingTitle: 'Создаём...',
            systemRoles: value.systemRoles
                .where((role) => role.code != 'OWNER')
                .toList(growable: false),
            customRoles: value.customRoles,
            selectedRoleId: value.selectedRoleId,
            customRoleTitle: value.customRoleTitle,
            customRoleController: _customRoleController,
            permissions: value.permissions,
            isSubmitting: value.isSubmitting,
            onRoleSelected: (roleId) => ref
                .read(aclCreateInviteControllerProvider(widget.petId).notifier)
                .selectRole(roleId),
            onCustomRoleChanged: (text) => ref
                .read(aclCreateInviteControllerProvider(widget.petId).notifier)
                .setCustomRoleTitle(text),
            onReadChanged: (domain, allowed) => ref
                .read(aclCreateInviteControllerProvider(widget.petId).notifier)
                .setReadPermission(domain, allowed),
            onWriteChanged: (domain, allowed) => ref
                .read(aclCreateInviteControllerProvider(widget.petId).notifier)
                .setWritePermission(domain, allowed),
            onSubmit: _submitCreate,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _AclInviteFormErrorView(
          title: 'Не удалось открыть экран приглашения',
          message:
              'Попробуйте перезагрузить экран и снова выбрать роль и права.',
          onRetry: () => ref
              .read(aclCreateInviteControllerProvider(widget.petId).notifier)
              .reload(),
        ),
      ),
    );
  }

  Widget _buildEditMode() {
    final state = ref.watch(aclAccessControllerProvider(widget.petId));

    return PawlyScreenScaffold(
      title: 'Редактирование приглашения',
      body: state.when(
        data: (value) {
          final invite = _inviteById(value.invites, widget.inviteId!);
          if (invite == null) {
            return _AclInviteFormErrorView(
              title: 'Приглашение не найдено',
              message: 'Возможно, приглашение уже было отозвано.',
              onRetry: () => ref
                  .read(aclAccessControllerProvider(widget.petId).notifier)
                  .reload(),
            );
          }
          _initializeEditState(value, invite);

          return _AclInviteFormContent(
            title: 'Сохранить приглашение',
            submittingTitle: 'Сохраняем...',
            systemRoles: value.roles
                .where((role) => role.kind == 'SYSTEM')
                .where((role) => role.code != 'OWNER')
                .toList(growable: false),
            customRoles: value.roles
                .where((role) => role.kind == 'CUSTOM')
                .toList(growable: false),
            selectedRoleId: _selectedRoleId,
            customRoleTitle: _customRoleController.text,
            customRoleController: _customRoleController,
            permissions: _permissions!,
            isSubmitting: _isSubmitting,
            onRoleSelected: (roleId) => _selectEditRole(value, roleId),
            onCustomRoleChanged: _setEditCustomRole,
            onReadChanged: _setEditReadPermission,
            onWriteChanged: _setEditWritePermission,
            onSubmit: () => _submitEdit(invite),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _AclInviteFormErrorView(
          title: 'Не удалось открыть приглашение',
          message: 'Попробуйте обновить экран.',
          onRetry: () => ref
              .read(aclAccessControllerProvider(widget.petId).notifier)
              .reload(),
        ),
      ),
    );
  }

  void _syncCustomRoleController(String value) {
    if (_customRoleController.text == value) {
      return;
    }
    _customRoleController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _submitCreate() async {
    try {
      final result = await ref
          .read(aclCreateInviteControllerProvider(widget.petId).notifier)
          .submit();
      if (!mounted) {
        return;
      }
      context.pushReplacementNamed(
        'aclInviteDetails',
        pathParameters: <String, String>{
          'petId': widget.petId,
          'inviteId': result.invite.id,
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _aclInviteErrorMessage(error, 'Не удалось создать приглашение.'),
          ),
        ),
      );
    }
  }

  void _initializeEditState(AclAccessScreenState state, AclInvite invite) {
    if (_initializedEditState) {
      return;
    }
    _initializedEditState = true;
    _selectedRoleId = invite.role.id;
    _selectedPresetId = invite.basePresetId;
    _permissions = AclPermissionDraft.fromPolicy(invite.policy);
    _customRoleController.clear();

    if (_selectedPresetId != null && _selectedPresetId!.isNotEmpty) {
      final preset = _presetById(state.presets, _selectedPresetId!);
      if (preset != null) {
        _permissions = AclPermissionDraft.fromPolicy(preset.policy);
      }
    }
  }

  void _selectEditRole(AclAccessScreenState state, String? roleId) {
    if (roleId == null || _isSubmitting) {
      return;
    }
    final role = _roleById(state.roles, roleId);
    final preset = role == null ? null : _presetForRole(state.presets, role);

    setState(() {
      _selectedRoleId = roleId;
      _selectedPresetId = preset?.id;
      _customRoleController.clear();
      if (role != null) {
        _permissions = AclPermissionDraft.fromPolicy(role.policy);
      }
    });
  }

  void _setEditCustomRole(String value) {
    setState(() {
      _selectedRoleId = null;
      _selectedPresetId = null;
    });
  }

  void _setEditReadPermission(AclPermissionDomain domain, bool value) {
    final current = _permissions;
    if (current == null || _isSubmitting) {
      return;
    }
    setState(() {
      _selectedPresetId = null;
      _permissions = current.updateRead(domain, value);
    });
  }

  void _setEditWritePermission(AclPermissionDomain domain, bool value) {
    final current = _permissions;
    if (current == null || _isSubmitting) {
      return;
    }
    setState(() {
      _selectedPresetId = null;
      _permissions = current.updateWrite(domain, value);
    });
  }

  Future<void> _submitEdit(AclInvite invite) async {
    final customRoleTitle = _customRoleController.text.trim();
    final hasRoleId = _selectedRoleId != null && _selectedRoleId!.isNotEmpty;
    final hasCustomRole = customRoleTitle.isNotEmpty;
    if (hasRoleId == hasCustomRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите роль или введите название новой роли.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(aclRepositoryProvider).createInvite(
            AclCreateInviteInput(
              petId: widget.petId,
              roleId: hasRoleId ? _selectedRoleId : null,
              customRoleTitle: hasCustomRole ? customRoleTitle : null,
              basePresetId: _selectedPresetId,
              policy: _permissions!.toPolicy(),
            ),
          );
      await ref.read(aclRepositoryProvider).revokeInvite(
            petId: widget.petId,
            inviteId: invite.id,
          );
      ref.invalidate(aclAccessControllerProvider(widget.petId));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result.invite.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _aclInviteErrorMessage(error, 'Не удалось обновить приглашение.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _AclInviteFormContent extends StatelessWidget {
  const _AclInviteFormContent({
    required this.title,
    required this.submittingTitle,
    required this.systemRoles,
    required this.customRoles,
    required this.selectedRoleId,
    required this.customRoleTitle,
    required this.customRoleController,
    required this.permissions,
    required this.isSubmitting,
    required this.onRoleSelected,
    required this.onCustomRoleChanged,
    required this.onReadChanged,
    required this.onWriteChanged,
    required this.onSubmit,
  });

  final String title;
  final String submittingTitle;
  final List<AclRole> systemRoles;
  final List<AclRole> customRoles;
  final String? selectedRoleId;
  final String customRoleTitle;
  final TextEditingController customRoleController;
  final AclPermissionDraft permissions;
  final bool isSubmitting;
  final ValueChanged<String?> onRoleSelected;
  final ValueChanged<String> onCustomRoleChanged;
  final void Function(AclPermissionDomain domain, bool value) onReadChanged;
  final void Function(AclPermissionDomain domain, bool value) onWriteChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedRole = _roleById(
      <AclRole>[...systemRoles, ...customRoles],
      selectedRoleId ?? '',
    );
    final normalizedCustomRoleTitle = customRoleTitle.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        _InviteSection(
          title: 'Роль',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (systemRoles.isNotEmpty) ...<Widget>[
                Text(
                  'Системные роли',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                _InviteRoleList(
                  roles: systemRoles,
                  selectedRoleId: selectedRoleId,
                  labelBuilder: _localizedRoleTitle,
                  isEnabled: !isSubmitting,
                  onRoleSelected: onRoleSelected,
                ),
              ],
              if (customRoles.isNotEmpty) ...<Widget>[
                const SizedBox(height: PawlySpacing.md),
                Text(
                  'Кастомные роли',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Wrap(
                  spacing: PawlySpacing.xs,
                  runSpacing: PawlySpacing.xs,
                  children: customRoles.map((role) {
                    return _InviteRolePill(
                      label: role.title,
                      isSelected: selectedRoleId == role.id,
                      isEnabled: !isSubmitting,
                      onTap: () => onRoleSelected(role.id),
                    );
                  }).toList(growable: false),
                ),
              ],
              const SizedBox(height: PawlySpacing.md),
              PawlyTextField(
                controller: customRoleController,
                label: 'Новая роль',
                hintText: 'Например, Семейный помощник',
                textCapitalization: TextCapitalization.sentences,
                onChanged: onCustomRoleChanged,
                enabled: !isSubmitting,
              ),
              if (selectedRole != null ||
                  normalizedCustomRoleTitle.isNotEmpty) ...<Widget>[
                const SizedBox(height: PawlySpacing.sm),
                Text(
                  selectedRole != null
                      ? 'Выбрана роль: ${_localizedRoleTitle(selectedRole)}'
                      : 'Новая роль: $normalizedCustomRoleTitle',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        _InviteSection(
          title: 'Права',
          child: _AclPermissionsList(
            draft: permissions,
            isEnabled: !isSubmitting,
            onReadChanged: onReadChanged,
            onWriteChanged: onWriteChanged,
          ),
        ),
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: isSubmitting ? submittingTitle : title,
          onPressed: isSubmitting ? null : onSubmit,
        ),
      ],
    );
  }
}

class _InviteSection extends StatelessWidget {
  const _InviteSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PawlySpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _InviteRoleList extends StatelessWidget {
  const _InviteRoleList({
    required this.roles,
    required this.selectedRoleId,
    required this.labelBuilder,
    required this.isEnabled,
    required this.onRoleSelected,
  });

  final List<AclRole> roles;
  final String? selectedRoleId;
  final String Function(AclRole role) labelBuilder;
  final bool isEnabled;
  final ValueChanged<String?> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List<Widget>.generate(roles.length, (index) {
          final role = roles[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == roles.length - 1 ? 0 : PawlySpacing.xs,
            ),
            child: _InviteRolePill(
              label: labelBuilder(role),
              isSelected: selectedRoleId == role.id,
              isEnabled: isEnabled,
              onTap: () => onRoleSelected(role.id),
            ),
          );
        }),
      ),
    );
  }
}

class _InviteRolePill extends StatelessWidget {
  const _InviteRolePill({
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.54,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(PawlyRadius.pill),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.84),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.xs,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AclPermissionsList extends StatelessWidget {
  const _AclPermissionsList({
    required this.draft,
    required this.isEnabled,
    required this.onReadChanged,
    required this.onWriteChanged,
  });

  final AclPermissionDraft draft;
  final bool isEnabled;
  final void Function(AclPermissionDomain domain, bool value) onReadChanged;
  final void Function(AclPermissionDomain domain, bool value) onWriteChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: draft.items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.42,
              ),
              borderRadius: BorderRadius.circular(PawlyRadius.lg),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.64),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(PawlySpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _domainLabel(item.domain),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: PawlySpacing.sm),
                  _InvitePermissionSwitch(
                    label: 'Просмотр',
                    value: item.canRead,
                    onChanged: isEnabled
                        ? (value) => onReadChanged(item.domain, value)
                        : null,
                  ),
                  const SizedBox(width: PawlySpacing.sm),
                  _InvitePermissionSwitch(
                    label: 'Изменение',
                    value: item.canWrite,
                    onChanged: isEnabled
                        ? (value) => onWriteChanged(item.domain, value)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _InvitePermissionSwitch extends StatelessWidget {
  const _InvitePermissionSwitch({
    required this.label,
    required this.value,
    this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PawlySpacing.xxs),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _AclInviteFormErrorView extends StatelessWidget {
  const _AclInviteFormErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyButton(
                  label: 'Повторить',
                  onPressed: onRetry,
                  variant: PawlyButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

AclInvite? _inviteById(List<AclInvite> invites, String inviteId) {
  for (final invite in invites) {
    if (invite.id == inviteId) {
      return invite;
    }
  }
  return null;
}

AclRole? _roleById(List<AclRole> roles, String roleId) {
  for (final role in roles) {
    if (role.id == roleId) {
      return role;
    }
  }
  return null;
}

AclPreset? _presetById(List<AclPreset> presets, String presetId) {
  for (final preset in presets) {
    if (preset.id == presetId) {
      return preset;
    }
  }
  return null;
}

AclPreset? _presetForRole(List<AclPreset> presets, AclRole role) {
  final roleCode = role.code;
  if (roleCode == null || roleCode.isEmpty) {
    return null;
  }

  for (final preset in presets) {
    if (preset.roleCode == roleCode) {
      return preset;
    }
  }
  return null;
}

String _localizedRoleTitle(AclRole role) {
  return switch (role.code) {
    'OWNER' => 'Владелец',
    'CO_OWNER' => 'Совладелец',
    'VET' => 'Ветеринар',
    'PETSITTER' => 'Петситтер',
    'WALKER' => 'Выгул',
    _ => role.title,
  };
}

String _domainLabel(AclPermissionDomain domain) {
  return switch (domain) {
    AclPermissionDomain.pet => 'Питомец',
    AclPermissionDomain.log => 'Записи',
    AclPermissionDomain.health => 'Здоровье',
    AclPermissionDomain.members => 'Участники',
  };
}

String _aclInviteErrorMessage(Object error, String fallback) {
  if (error is StateError) {
    return error.message.toString();
  }
  return fallback;
}
