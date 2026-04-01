import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/acl_models.dart';
import '../../../../design_system/design_system.dart';
import '../models/acl_screen_models.dart';
import '../providers/acl_controllers.dart';

class AclCreateInvitePage extends ConsumerStatefulWidget {
  const AclCreateInvitePage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<AclCreateInvitePage> createState() =>
      _AclCreateInvitePageState();
}

class _AclCreateInvitePageState extends ConsumerState<AclCreateInvitePage> {
  late final TextEditingController _customRoleController;

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
    final state = ref.watch(aclCreateInviteControllerProvider(widget.petId));

    return Scaffold(
      appBar: AppBar(title: const Text('Новое приглашение')),
      body: state.when(
        data: (value) {
          if (_customRoleController.text != value.customRoleTitle) {
            _customRoleController.value = TextEditingValue(
              text: value.customRoleTitle,
              selection: TextSelection.collapsed(
                offset: value.customRoleTitle.length,
              ),
            );
          }

          return _AclCreateInviteContent(
            state: value,
            customRoleController: _customRoleController,
            onRoleSelected: (roleId) => ref
                .read(aclCreateInviteControllerProvider(widget.petId).notifier)
                .selectRole(roleId),
            onCustomRoleChanged: (value) => ref
                .read(aclCreateInviteControllerProvider(widget.petId).notifier)
                .setCustomRoleTitle(value),
            onReadChanged: (domain, value) => ref
                .read(aclCreateInviteControllerProvider(widget.petId).notifier)
                .setReadPermission(domain, value),
            onWriteChanged: (domain, value) => ref
                .read(aclCreateInviteControllerProvider(widget.petId).notifier)
                .setWritePermission(domain, value),
            onSubmit: _submit,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _AclCreateInviteErrorView(
          onRetry: () => ref
              .read(aclCreateInviteControllerProvider(widget.petId).notifier)
              .reload(),
        ),
      ),
    );
  }

  Future<void> _submit() async {
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
            error is StateError
                ? error.message.toString()
                : 'Не удалось создать приглашение.',
          ),
        ),
      );
    }
  }
}

class _AclCreateInviteContent extends StatelessWidget {
  const _AclCreateInviteContent({
    required this.state,
    required this.customRoleController,
    required this.onRoleSelected,
    required this.onCustomRoleChanged,
    required this.onReadChanged,
    required this.onWriteChanged,
    required this.onSubmit,
  });

  final AclCreateInviteState state;
  final TextEditingController customRoleController;
  final ValueChanged<String?> onRoleSelected;
  final ValueChanged<String> onCustomRoleChanged;
  final void Function(AclPermissionDomain domain, bool value) onReadChanged;
  final void Function(AclPermissionDomain domain, bool value) onWriteChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final systemRoles = state.systemRoles
        .where((role) => role.code != 'OWNER')
        .toList(growable: false);
    final customRoles = state.customRoles;
    final selectedRole = state.roleById(state.selectedRoleId);

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
            separatorBuilder: (_, __) => const SizedBox(width: PawlySpacing.xs),
            itemBuilder: (context, index) {
              final role = systemRoles[index];
              return ChoiceChip(
                label: Text(_localizedRoleTitle(role)),
                selected: state.selectedRoleId == role.id,
                onSelected: (_) => onRoleSelected(role.id),
              );
            },
          ),
        ),
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
            children: customRoles.map((role) {
              return ChoiceChip(
                label: Text(role.title),
                selected: state.selectedRoleId == role.id,
                onSelected: (_) => onRoleSelected(role.id),
              );
            }).toList(growable: false),
          ),
        ],
        const SizedBox(height: PawlySpacing.lg),
        Text(
          'Или создайте новую роль',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        PawlyTextField(
          controller: customRoleController,
          label: 'Кастомная роль',
          hintText: 'Например, Семейный помощник',
          textCapitalization: TextCapitalization.sentences,
          onChanged: onCustomRoleChanged,
        ),
        if (selectedRole != null || state.hasCustomRoleTitle) ...<Widget>[
          const SizedBox(height: PawlySpacing.sm),
          Text(
            selectedRole != null
                ? 'Выбрана роль: ${_localizedRoleTitle(selectedRole)}'
                : 'Новая роль: ${state.normalizedCustomRoleTitle}',
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
          draft: state.permissions,
          onReadChanged: onReadChanged,
          onWriteChanged: onWriteChanged,
        ),
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: state.isSubmitting ? 'Создаем...' : 'Создать приглашение',
          onPressed: state.isSubmitting ? null : onSubmit,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }
}

class _AclPermissionsTable extends StatelessWidget {
  const _AclPermissionsTable({
    required this.draft,
    required this.onReadChanged,
    required this.onWriteChanged,
  });

  final AclPermissionDraft draft;
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
                        onChanged: (value) =>
                            onReadChanged(item.domain, value ?? false),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Checkbox(
                        value: item.canWrite,
                        onChanged: (value) =>
                            onWriteChanged(item.domain, value ?? false),
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

class _AclCreateInviteErrorView extends StatelessWidget {
  const _AclCreateInviteErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось открыть экран приглашения'),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: const Text(
            'Попробуйте перезагрузить экран и снова выбрать роль и права.',
          ),
        ),
      ),
    );
  }
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
