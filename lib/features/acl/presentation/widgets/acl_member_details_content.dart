import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/acl_member.dart';
import '../../models/acl_permission.dart';
import '../../shared/widgets/acl_avatar.dart';
import '../../shared/widgets/acl_form_section.dart';
import '../../shared/widgets/acl_message_button.dart';
import '../../shared/widgets/acl_permission_editor.dart';
import '../../shared/widgets/acl_role_list.dart';
import '../../states/acl_member_details_state.dart';

class AclMemberDetailsContent extends StatelessWidget {
  const AclMemberDetailsContent({
    required this.state,
    required this.onRoleSelected,
    required this.onReadChanged,
    required this.onWriteChanged,
    required this.onSave,
    required this.onRevoke,
    required this.onLeave,
    required this.onOwnerTransferPressed,
    this.onMessageTap,
    super.key,
  });

  final AclMemberDetailsState state;
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
    final member = state.member;
    final canManage = state.capabilities.membersWrite;
    final isMe = member.userId == state.me.userId;
    final canEdit = canManage && !member.isPrimaryOwner && !isMe;
    final canRevoke = canEdit && !isMe;
    final canTransferOwnership =
        state.me.isPrimaryOwner && !member.isPrimaryOwner;
    final systemRoles = state.systemRoles;
    final customRoles = state.customRoles;

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
        AclFormSection(
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
              else if (isMe)
                Text(
                  'Себе нельзя менять роль.',
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
                  AclRoleList(
                    roles: systemRoles,
                    selectedRoleId: state.selectedRoleId,
                    isEnabled: canEdit,
                    onRoleSelected: onRoleSelected,
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
                  AclRoleList(
                    roles: customRoles,
                    selectedRoleId: state.selectedRoleId,
                    isEnabled: canEdit,
                    onRoleSelected: onRoleSelected,
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        AclFormSection(
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
              else if (isMe)
                Text(
                  'Себе нельзя менять права доступа.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else ...<Widget>[
                AclPermissionEditor(
                  draft: state.permissions,
                  isEnabled: canEdit && !state.isSubmitting,
                  onReadChanged: onReadChanged,
                  onWriteChanged: onWriteChanged,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        AclFormSection(
          title: 'Действия',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (canEdit)
                PawlyButton(
                  label:
                      state.isSubmitting ? 'Сохраняем...' : 'Сохранить права',
                  onPressed: state.isSubmitting ? null : onSave,
                ),
              if (canRevoke) ...<Widget>[
                const SizedBox(height: PawlySpacing.sm),
                PawlyButton(
                  label: 'Отозвать доступ',
                  onPressed: state.isSubmitting ? null : onRevoke,
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
                  onPressed: state.isSubmitting ? null : onLeave,
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
    final name = member.displayName;

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
            AclAvatar(
              userId: member.userId,
              photoUrl: profile?.avatarUrl,
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
                        : 'Роль: ${member.roleTitle}',
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
              AclMessageButton(
                onTap: onMessageTap!,
                size: 42,
                iconSize: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
