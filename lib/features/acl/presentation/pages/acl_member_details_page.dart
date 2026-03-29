import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/models/acl_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../chat/data/chat_repository_models.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Участник')),
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
      if (preset != null) {
        _permissions = AclPermissionDraft.fromPolicy(preset.policy);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите роль участника.')),
      );
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
                _aclErrorMessage(error, 'Не удалось обновить участника.'))),
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
            content:
                Text(_aclErrorMessage(error, 'Не удалось отозвать доступ.'))),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Передача роли владельца запущена.')),
    );
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
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        _MemberSummaryCard(
          member: member,
          onMessageTap: onMessageTap,
        ),
        const SizedBox(height: PawlySpacing.md),
        PawlyCard(
          title: Text(
            'Роль',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
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
                          (role) => ChoiceChip(
                            label: Text(_localizedRoleTitle(role)),
                            selected: selectedRoleId == role.id,
                            onSelected:
                                canEdit ? (_) => onRoleSelected(role.id) : null,
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
                          (role) => ChoiceChip(
                            label: Text(role.title),
                            selected: selectedRoleId == role.id,
                            onSelected:
                                canEdit ? (_) => onRoleSelected(role.id) : null,
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
        PawlyCard(
          title: Text(
            'Права доступа',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
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
        PawlyCard(
          title: Text(
            'Действия',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (canEdit)
                PawlyButton(
                  label: isSubmitting ? 'Сохраняем...' : 'Сохранить права',
                  onPressed: isSubmitting ? null : onSave,
                  icon: Icons.check_rounded,
                ),
              if (canRevoke) ...<Widget>[
                const SizedBox(height: PawlySpacing.sm),
                PawlyButton(
                  label: 'Отозвать доступ',
                  onPressed: isSubmitting ? null : onRevoke,
                  variant: PawlyButtonVariant.secondary,
                  icon: Icons.person_remove_alt_1_rounded,
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
                  icon: Icons.workspace_premium_rounded,
                ),
              ],
              if (isMe && !member.isPrimaryOwner) ...<Widget>[
                const SizedBox(height: PawlySpacing.sm),
                Text(
                  'Свой доступ отозвать нельзя.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
  const _MemberSummaryCard({
    required this.member,
    this.onMessageTap,
  });

  final AclMember member;
  final VoidCallback? onMessageTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = member.profile;
    final name = _memberName(profile);

    return PawlyCard(
      trailing: onMessageTap == null
          ? null
          : IconButton(
              onPressed: onMessageTap,
              tooltip: 'Открыть чат',
              icon: const Icon(Icons.chat_bubble_rounded),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _AclAvatar(
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Wrap(
                  spacing: PawlySpacing.xs,
                  runSpacing: PawlySpacing.xs,
                  children: <Widget>[
                    if (member.isPrimaryOwner)
                      const PawlyBadge(
                        label: 'Владелец',
                        tone: PawlyBadgeTone.warning,
                      )
                    else
                      PawlyBadge(
                        label: _localizedRoleTitle(member.role),
                        tone: PawlyBadgeTone.neutral,
                      ),
                    PawlyBadge(
                      label: _memberStatusLabel(member.status),
                      tone: member.status == 'ACTIVE'
                          ? PawlyBadgeTone.success
                          : PawlyBadgeTone.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: PawlySpacing.xs),
          Row(
            children: <Widget>[
              Expanded(
                child: SwitchListTile.adaptive(
                  value: selection.canRead,
                  onChanged: enabled ? onReadChanged : null,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Чтение'),
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              Expanded(
                child: SwitchListTile.adaptive(
                  value: selection.canWrite,
                  onChanged: enabled ? onWriteChanged : null,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Изменение'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AclAvatar extends StatelessWidget {
  const _AclAvatar({
    required this.photoUrl,
    required this.fallbackLabel,
    required this.showCrown,
  });

  final String? photoUrl;
  final String fallbackLabel;
  final bool showCrown;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final resolvedPhotoUrl = hasPhoto ? _normalizeStorageUrl(photoUrl!) : null;

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? CachedNetworkImage(
                    imageUrl: resolvedPhotoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _AclAvatarFallback(label: fallbackLabel),
                  )
                : _AclAvatarFallback(label: fallbackLabel),
          ),
          if (showCrown)
            Positioned(
              top: -4,
              right: -2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(PawlyRadius.pill),
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: Colors.black87,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить участника'),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: const Text(
            'Участник не найден или список доступа еще не обновился.',
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

String _memberStatusLabel(String status) {
  return switch (status) {
    'ACTIVE' => 'Активен',
    'REMOVED' => 'Отозван',
    _ => status,
  };
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
              OpenDirectChatInput(
                petId: petId,
                otherUserId: otherUserId,
              ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось открыть чат.')),
    );
  }
}
