import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/acl_models.dart';
import '../../../../design_system/design_system.dart';
import '../../data/acl_repository_models.dart';
import '../models/acl_screen_models.dart';
import '../providers/acl_controllers.dart';

class AclEditInvitePage extends ConsumerStatefulWidget {
  const AclEditInvitePage({
    required this.petId,
    required this.inviteId,
    super.key,
  });

  final String petId;
  final String inviteId;

  @override
  ConsumerState<AclEditInvitePage> createState() => _AclEditInvitePageState();
}

class _AclEditInvitePageState extends ConsumerState<AclEditInvitePage> {
  late final TextEditingController _customRoleController;
  String? _selectedRoleId;
  String? _selectedPresetId;
  AclPermissionDraft? _permissions;
  bool _isSubmitting = false;
  bool _initialized = false;

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
    final stateAsync = ref.watch(aclAccessControllerProvider(widget.petId));

    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование приглашения')),
      body: stateAsync.when(
        data: (state) {
          final invite = _inviteById(state.invites, widget.inviteId);
          if (invite == null) {
            return _AclEditInviteErrorView(
              title: 'Приглашение не найдено',
              message: 'Возможно, приглашение уже было отозвано.',
              onRetry: () => ref
                  .read(aclAccessControllerProvider(widget.petId).notifier)
                  .reload(),
            );
          }

          _initializeIfNeeded(state, invite);

          return _AclEditInviteContent(
            state: state,
            selectedRoleId: _selectedRoleId,
            customRoleController: _customRoleController,
            permissions: _permissions!,
            isSubmitting: _isSubmitting,
            onRoleSelected: (roleId) => _selectRole(state, roleId),
            onCustomRoleChanged: _setCustomRole,
            onReadChanged: _setReadPermission,
            onWriteChanged: _setWritePermission,
            onSubmit: () => _submit(invite),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _AclEditInviteErrorView(
          title: 'Не удалось открыть приглашение',
          message: 'Попробуйте обновить экран.',
          onRetry: () => ref
              .read(aclAccessControllerProvider(widget.petId).notifier)
              .reload(),
        ),
      ),
    );
  }

  void _initializeIfNeeded(AclAccessScreenState state, AclInvite invite) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _selectedRoleId = invite.role.id;
    _selectedPresetId = invite.basePresetId;
    _permissions = AclPermissionDraft.fromPolicy(invite.policy);
    _customRoleController.text = '';
    if (_selectedPresetId != null && _selectedPresetId!.isNotEmpty) {
      final preset = _presetById(state.presets, _selectedPresetId!);
      if (preset != null) {
        _permissions = AclPermissionDraft.fromPolicy(preset.policy);
      }
    }
  }

  void _selectRole(AclAccessScreenState state, String? roleId) {
    if (roleId == null) {
      return;
    }

    final role = _roleById(state.roles, roleId);
    final preset = role == null ? null : _presetForRole(state.presets, role);
    setState(() {
      _selectedRoleId = roleId;
      _customRoleController.clear();
      _selectedPresetId = preset?.id;
      if (preset != null) {
        _permissions = AclPermissionDraft.fromPolicy(preset.policy);
      }
    });
  }

  void _setCustomRole(String value) {
    setState(() {
      _selectedRoleId = null;
      _selectedPresetId = null;
    });
  }

  void _setReadPermission(AclPermissionDomain domain, bool value) {
    final current = _permissions;
    if (current == null) {
      return;
    }

    setState(() {
      _selectedPresetId = null;
      _permissions = current.updateRead(domain, value);
    });
  }

  void _setWritePermission(AclPermissionDomain domain, bool value) {
    final current = _permissions;
    if (current == null) {
      return;
    }

    setState(() {
      _selectedPresetId = null;
      _permissions = current.updateWrite(domain, value);
    });
  }

  Future<void> _submit(AclInvite invite) async {
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
          content: Text(_aclInviteErrorMessage(
              error, 'Не удалось обновить приглашение.')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _AclEditInviteContent extends StatelessWidget {
  const _AclEditInviteContent({
    required this.state,
    required this.selectedRoleId,
    required this.customRoleController,
    required this.permissions,
    required this.isSubmitting,
    required this.onRoleSelected,
    required this.onCustomRoleChanged,
    required this.onReadChanged,
    required this.onWriteChanged,
    required this.onSubmit,
  });

  final AclAccessScreenState state;
  final String? selectedRoleId;
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
    final systemRoles = state.roles
        .where((role) => role.kind == 'SYSTEM')
        .where((role) => role.code != 'OWNER')
        .toList(growable: false);
    final customRoles = state.roles
        .where((role) => role.kind == 'CUSTOM')
        .toList(growable: false);
    final selectedRole = _roleById(state.roles, selectedRoleId ?? '');

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        Text(
          'Роль',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PawlySpacing.sm),
        if (systemRoles.isNotEmpty) ...<Widget>[
          Text(
            'Системные роли',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: systemRoles.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: PawlySpacing.xs),
              itemBuilder: (context, index) {
                final role = systemRoles[index];
                return ChoiceChip(
                  label: Text(_localizedRoleTitle(role)),
                  selected: selectedRoleId == role.id,
                  onSelected:
                      isSubmitting ? null : (_) => onRoleSelected(role.id),
                );
              },
            ),
          ),
        ],
        if (customRoles.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          Text(
            'Существующие кастомные роли',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          Wrap(
            spacing: PawlySpacing.xs,
            runSpacing: PawlySpacing.xs,
            children: customRoles
                .map(
                  (role) => ChoiceChip(
                    label: Text(role.title),
                    selected: selectedRoleId == role.id,
                    onSelected:
                        isSubmitting ? null : (_) => onRoleSelected(role.id),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: PawlySpacing.lg),
        Text(
          'Или укажите новую роль',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
            customRoleController.text.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.sm),
          Text(
            selectedRole != null
                ? 'Выбрана роль: ${_localizedRoleTitle(selectedRole)}'
                : 'Новая роль: ${customRoleController.text.trim()}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: PawlySpacing.lg),
        Text(
          'Права',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PawlySpacing.sm),
        _AclPermissionsTable(
          draft: permissions,
          enabled: !isSubmitting,
          onReadChanged: onReadChanged,
          onWriteChanged: onWriteChanged,
        ),
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: isSubmitting ? 'Сохраняем...' : 'Сохранить приглашение',
          onPressed: isSubmitting ? null : onSubmit,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }
}

class _AclPermissionsTable extends StatelessWidget {
  const _AclPermissionsTable({
    required this.draft,
    required this.enabled,
    required this.onReadChanged,
    required this.onWriteChanged,
  });

  final AclPermissionDraft draft;
  final bool enabled;
  final void Function(AclPermissionDomain domain, bool value) onReadChanged;
  final void Function(AclPermissionDomain domain, bool value) onWriteChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PawlyCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PawlySpacing.md,
              vertical: PawlySpacing.sm,
            ),
            decoration: BoxDecoration(
              color:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(PawlyRadius.lg),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Text(
                    'Домен',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Просмотр',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Изменение',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...draft.items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: PawlySpacing.md,
                vertical: PawlySpacing.xs,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Text(
                      _domainLabel(item.domain),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Checkbox(
                        value: item.canRead,
                        onChanged: enabled
                            ? (value) =>
                                onReadChanged(item.domain, value ?? false)
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Checkbox(
                        value: item.canWrite,
                        onChanged: enabled
                            ? (value) =>
                                onWriteChanged(item.domain, value ?? false)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AclEditInviteErrorView extends StatelessWidget {
  const _AclEditInviteErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: Text(title),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: Text(message),
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
