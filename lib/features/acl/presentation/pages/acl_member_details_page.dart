import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/models/acl_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../chat/data/chat_repository_models.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../pets/controllers/active_pet_controller.dart';
import '../../../pets/controllers/active_pet_details_controller.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../models/acl_screen_models.dart';
import '../providers/acl_controllers.dart';

class AclMemberDetailsPage extends ConsumerStatefulWidget {
  const AclMemberDetailsPage({
    required this.petId,
    required this.memberId,
    super.key,
  });

  final String petId;
  final String memberId;

  @override
  ConsumerState<AclMemberDetailsPage> createState() =>
      _AclMemberDetailsPageState();
}

class _AclMemberDetailsPageState extends ConsumerState<AclMemberDetailsPage> {
  String? _selectedRoleId;
  String? _selectedPresetId;
  AclPermissionDraft? _permissions;
  String? _syncToken;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(aclAccessControllerProvider(widget.petId));

    return PawlyScreenScaffold(
      title: 'Участник',
      body: accessState.when(
        data: (state) {
          final member = _memberById(state.members, widget.memberId);
          if (member == null) {
            return _AclMemberMissingView(
              onRetry: () => ref
                  .read(aclAccessControllerProvider(widget.petId).notifier)
                  .reload(),
            );
          }

          _syncDraftIfNeeded(member, state);
          return _AclMemberDetailsContent(
            state: state,
            member: member,
            selectedRoleId: _selectedRoleId,
            permissions: _permissions!,
            isSubmitting: _isSubmitting,
            onRoleSelected: (value) => _selectRole(state, value),
            onReadChanged: _setReadPermission,
            onWriteChanged: _setWritePermission,
            onSave: () => _saveChanges(member),
            onRevoke: () => _revokeAccess(member),
            onLeave: () => _leaveAccess(member),
            onOwnerTransferPressed: () => _showOwnerTransferDialog(member),
            onMessageTap: member.userId == state.me.userId
                ? null
                : () => _openDirectChat(
                      context: context,
                      ref: ProviderScope.containerOf(context),
                      petId: state.me.petId,
                      otherUserId: member.userId,
                    ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _AclMemberMissingView(
          onRetry: () => ref
              .read(aclAccessControllerProvider(widget.petId).notifier)
              .reload(),
        ),
      ),
    );
  }

  void _syncDraftIfNeeded(AclMember member, AclAccessScreenState state) {
    final token = [
      member.id,
      member.role.id,
      member.updatedAt?.toIso8601String() ?? '',
      member.status,
    ].join('|');

    if (_syncToken == token && _permissions != null) {
      return;
    }

    final preset = _presetForRole(state.presets, member.role);
    _selectedRoleId = member.role.id;
    _selectedPresetId = preset?.id;
    _permissions = AclPermissionDraft.fromPolicy(member.policy);
    _syncToken = token;
  }

  void _selectRole(AclAccessScreenState state, String? roleId) {
    if (roleId == null) {
      return;
    }

    final role = _roleById(state.roles, roleId);
    final preset = role == null ? null : _presetForRole(state.presets, role);
    setState(() {
      _selectedRoleId = roleId;
      _selectedPresetId = preset?.id;
      if (role != null) {
        _permissions = AclPermissionDraft.fromPolicy(role.policy);
      }
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

  Future<void> _saveChanges(AclMember member) async {
    if (_selectedRoleId == null ||
        _selectedRoleId!.isEmpty ||
        _permissions == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите роль участника.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(aclAccessControllerProvider(widget.petId).notifier)
          .updateMember(
            memberId: member.id,
            roleId: _selectedRoleId!,
            basePresetId: _selectedPresetId,
            policy: _permissions!.toPolicy(),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Права участника обновлены.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _aclErrorMessage(error, 'Не удалось обновить участника.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _revokeAccess(AclMember member) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Отозвать доступ?'),
            content: const Text(
              'Участник потеряет доступ к питомцу. Это действие можно будет вернуть только новым приглашением.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Отозвать'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(aclAccessControllerProvider(widget.petId).notifier)
          .removeMember(member.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_aclErrorMessage(error, 'Не удалось отозвать доступ.')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showOwnerTransferDialog(AclMember member) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Передать роль владельца?'),
            content: Text(
              'После подтверждения ${_memberName(member.profile)} станет основным владельцем питомца.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Передать'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(aclAccessControllerProvider(widget.petId).notifier)
          .transferOwnership(targetMemberId: member.id);
      ref.invalidate(activePetDetailsControllerProvider);
      await ref.read(petsControllerProvider.notifier).refreshAfterPetMutation();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_memberName(member.profile)} теперь основной владелец питомца.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _aclErrorMessage(error, 'Не удалось передать роль владельца.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _leaveAccess(AclMember member) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Выйти из ухода за питомцем?'),
            content: const Text(
              'Вы потеряете доступ к питомцу и сможете вернуться только по новому приглашению.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Выйти'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(aclAccessControllerProvider(widget.petId).notifier)
          .leaveMyAccess();
      await ref.read(activePetControllerProvider.notifier).clear();
      ref.invalidate(activePetDetailsControllerProvider);
      await ref.read(petsControllerProvider.notifier).reload();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_memberName(member.profile)} больше не участвует в уходе за питомцем.',
          ),
        ),
      );
      context.goNamed('pets');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _aclErrorMessage(error, 'Не удалось выйти из ухода за питомцем.'),
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

class _AclMemberDetailsContent extends StatelessWidget {
  const _AclMemberDetailsContent({
    required this.state,
    required this.member,
    required this.selectedRoleId,
    required this.permissions,
    required this.isSubmitting,
    required this.onRoleSelected,
    required this.onReadChanged,
    required this.onWriteChanged,
    required this.onSave,
    required this.onRevoke,
    required this.onLeave,
    required this.onOwnerTransferPressed,
    this.onMessageTap,
  });

  final AclAccessScreenState state;
  final AclMember member;
  final String? selectedRoleId;
  final AclPermissionDraft permissions;
  final bool isSubmitting;
  final ValueChanged<String?> onRoleSelected;
  final void Function(AclPermissionDomain domain, bool value) onReadChanged;
  final void Function(AclPermissionDomain domain, bool value) onWriteChanged;
  final VoidCallback onSave;
  final VoidCallback onRevoke;
  final VoidCallback onLeave;
  final VoidCallback onOwnerTransferPressed;
  final VoidCallback? onMessageTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = state.capabilities.membersWrite;
    final canEdit = canManage && !member.isPrimaryOwner;
    final isMe = member.userId == state.me.userId;
    final canRevoke = canEdit && !isMe;
    final canTransferOwnership =
        state.me.isPrimaryOwner && !member.isPrimaryOwner;
    final systemRoles = state.roles
        .where((role) => role.kind == 'SYSTEM' && role.code != 'OWNER')
        .toList(growable: false);
    final customRoles = state.roles
        .where((role) => role.kind == 'CUSTOM')
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        _MemberSummaryCard(member: member, onMessageTap: onMessageTap),
        const SizedBox(height: PawlySpacing.md),
        _AclDetailsSection(
          title: 'Роль',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (member.isPrimaryOwner)
                Text(
                  'Основной владелец питомца.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else ...<Widget>[
                if (systemRoles.isNotEmpty) ...<Widget>[
                  Text(
                    'Системные роли',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.sm),
                  Wrap(
                    spacing: PawlySpacing.xs,
                    runSpacing: PawlySpacing.xs,
                    children: systemRoles
                        .map(
                          (role) => _AclRolePill(
                            label: _localizedRoleTitle(role),
                            isSelected: selectedRoleId == role.id,
                            onTap:
                                canEdit ? () => onRoleSelected(role.id) : null,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                if (customRoles.isNotEmpty) ...<Widget>[
                  const SizedBox(height: PawlySpacing.md),
                  Text(
                    'Кастомные роли',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.sm),
                  Wrap(
                    spacing: PawlySpacing.xs,
                    runSpacing: PawlySpacing.xs,
                    children: customRoles
                        .map(
                          (role) => _AclRolePill(
                            label: role.title,
                            isSelected: selectedRoleId == role.id,
                            onTap:
                                canEdit ? () => onRoleSelected(role.id) : null,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        _AclDetailsSection(
          title: 'Права доступа',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (member.isPrimaryOwner)
                Text(
                  'Основной владелец всегда сохраняет полный доступ к питомцу.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else ...<Widget>[
                ...AclPermissionDomain.values.map(
                  (domain) => _PermissionEditorRow(
                    label: _permissionDomainLabel(domain),
                    selection: permissions.selectionFor(domain),
                    enabled: canEdit && !isSubmitting,
                    onReadChanged: (value) => onReadChanged(domain, value),
                    onWriteChanged: (value) => onWriteChanged(domain, value),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        _AclDetailsSection(
          title: 'Действия',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (canEdit)
                PawlyButton(
                  label: isSubmitting ? 'Сохраняем...' : 'Сохранить права',
                  onPressed: isSubmitting ? null : onSave,
                ),
              if (canRevoke) ...<Widget>[
                const SizedBox(height: PawlySpacing.sm),
                PawlyButton(
                  label: 'Отозвать доступ',
                  onPressed: isSubmitting ? null : onRevoke,
                  variant: PawlyButtonVariant.secondary,
                ),
              ],
              if (member.isPrimaryOwner) ...<Widget>[
                Text(
                  'У основного владельца нельзя отозвать доступ.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (canTransferOwnership) ...<Widget>[
                const SizedBox(height: PawlySpacing.sm),
                PawlyButton(
                  label: 'Передать роль владельца',
                  onPressed: onOwnerTransferPressed,
                  variant: PawlyButtonVariant.secondary,
                ),
              ],
              if (isMe && !member.isPrimaryOwner) ...<Widget>[
                const SizedBox(height: PawlySpacing.sm),
                PawlyButton(
                  label: 'Выйти из ухода',
                  onPressed: isSubmitting ? null : onLeave,
                  variant: PawlyButtonVariant.secondary,
                ),
              ],
              if (!canManage) ...<Widget>[
                Text(
                  'У вас нет права members_write для редактирования этого участника.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberSummaryCard extends StatelessWidget {
  const _MemberSummaryCard({required this.member, this.onMessageTap});

  final AclMember member;
  final VoidCallback? onMessageTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profile = member.profile;
    final name = _memberName(profile);

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _AclAvatar(
              userId: member.userId,
              photoUrl: profile?.avatarDownloadUrl,
              fallbackLabel: name,
              showCrown: member.isPrimaryOwner,
            ),
            const SizedBox(width: PawlySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.xxs),
                  Text(
                    member.isPrimaryOwner
                        ? 'Роль: основной владелец'
                        : 'Роль: ${_localizedRoleTitle(member.role)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onMessageTap != null) ...[
              const SizedBox(width: PawlySpacing.sm),
              _AclDetailsIconButton(onTap: onMessageTap!),
            ],
          ],
        ),
      ),
    );
  }
}

class _AclDetailsSection extends StatelessWidget {
  const _AclDetailsSection({required this.title, required this.child});

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

class _AclRolePill extends StatelessWidget {
  const _AclRolePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
    );
  }
}

class _AclDetailsIconButton extends StatelessWidget {
  const _AclDetailsIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.pill),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.64),
          ),
        ),
        child: Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _PermissionEditorRow extends StatelessWidget {
  const _PermissionEditorRow({
    required this.label,
    required this.selection,
    required this.enabled,
    required this.onReadChanged,
    required this.onWriteChanged,
  });

  final String label;
  final AclPermissionSelection selection;
  final bool enabled;
  final ValueChanged<bool> onReadChanged;
  final ValueChanged<bool> onWriteChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
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
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              _PermissionSwitch(
                label: 'Чтение',
                value: selection.canRead,
                enabled: enabled,
                onChanged: onReadChanged,
              ),
              const SizedBox(width: PawlySpacing.sm),
              _PermissionSwitch(
                label: 'Изменение',
                value: selection.canWrite,
                enabled: enabled,
                onChanged: onWriteChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionSwitch extends StatelessWidget {
  const _PermissionSwitch({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

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
        Switch(value: value, onChanged: enabled ? onChanged : null),
      ],
    );
  }
}

class _AclAvatar extends StatelessWidget {
  const _AclAvatar({
    required this.userId,
    required this.photoUrl,
    required this.fallbackLabel,
    required this.showCrown,
  });

  final String userId;
  final String? photoUrl;
  final String fallbackLabel;
  final bool showCrown;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final resolvedPhotoUrl = hasPhoto ? _normalizeStorageUrl(photoUrl!) : null;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.62,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.64),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? PawlyCachedImage(
                    imageUrl: resolvedPhotoUrl!,
                    cacheKey: pawlyStableImageCacheKey(
                      scope: 'acl-avatar',
                      entityId: userId,
                      imageUrl: resolvedPhotoUrl,
                    ),
                    targetLogicalSize: 56,
                    fit: BoxFit.cover,
                    errorWidget: (_) =>
                        _AclAvatarFallback(label: fallbackLabel),
                  )
                : _AclAvatarFallback(label: fallbackLabel),
          ),
          if (showCrown)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(PawlyRadius.pill),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                  ),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AclAvatarFallback extends StatelessWidget {
  const _AclAvatarFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = label.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);

    return Center(
      child: Text(
        letter.toUpperCase(),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AclMemberMissingView extends StatelessWidget {
  const _AclMemberMissingView({required this.onRetry});

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
                  'Не удалось загрузить участника',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Участник не найден или список доступа еще не обновился.',
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

AclMember? _memberById(List<AclMember> members, String memberId) {
  for (final member in members) {
    if (member.id == memberId) {
      return member;
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

String _memberName(AclMemberProfile? profile) {
  final firstName = profile?.firstName?.trim() ?? '';
  final lastName = profile?.lastName?.trim() ?? '';
  final fullName = '$firstName $lastName'.trim();
  if (fullName.isNotEmpty) {
    return fullName;
  }

  final displayName = profile?.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  return 'Участник';
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

String _permissionDomainLabel(AclPermissionDomain domain) {
  return switch (domain) {
    AclPermissionDomain.pet => 'Питомец',
    AclPermissionDomain.log => 'Журнал',
    AclPermissionDomain.health => 'Здоровье',
    AclPermissionDomain.members => 'Совместный доступ',
  };
}

String _aclErrorMessage(Object error, String fallback) {
  if (error is StateError) {
    return error.message.toString();
  }
  return fallback;
}

String _normalizeStorageUrl(String url) {
  final uri = Uri.tryParse(url);
  final apiUri = Uri.tryParse(ApiConstants.baseUrl);
  if (uri == null || apiUri == null || uri.host != 'minio') {
    return url;
  }

  return uri.replace(host: apiUri.host).toString();
}

Future<void> _openDirectChat({
  required BuildContext context,
  required ProviderContainer ref,
  required String petId,
  required String otherUserId,
}) async {
  try {
    final conversation =
        await ref.read(chatRepositoryProvider).openConversation(
              OpenDirectChatInput(petId: petId, otherUserId: otherUserId),
            );
    if (!context.mounted) {
      return;
    }
    context.pushNamed(
      'chatConversation',
      pathParameters: <String, String>{
        'conversationId': conversation.conversationId,
      },
    );
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Не удалось открыть чат.')));
  }
}
