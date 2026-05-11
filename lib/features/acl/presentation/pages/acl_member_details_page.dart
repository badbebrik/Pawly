import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/feature_flags.dart';
import '../../../../design_system/design_system.dart';
import '../../../pets/controllers/active_pet_controller.dart';
import '../../../pets/controllers/active_pet_details_controller.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../controllers/acl_member_details_controller.dart';
import '../../models/acl_member.dart';
import '../../models/acl_member_details_params.dart';
import '../../shared/formatters/acl_error_formatters.dart';
import '../../shared/utils/acl_chat_navigation.dart';
import '../../shared/widgets/acl_error_view.dart';
import '../widgets/acl_member_details_content.dart';

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
  @override
  Widget build(BuildContext context) {
    final params = AclMemberDetailsParams(
      petId: widget.petId,
      memberId: widget.memberId,
    );
    final memberState = ref.watch(aclMemberDetailsControllerProvider(params));

    return PawlyScreenScaffold(
      title: 'Участник',
      body: memberState.when(
        data: (state) {
          return AclMemberDetailsContent(
            state: state,
            onRoleSelected: (value) => ref
                .read(aclMemberDetailsControllerProvider(params).notifier)
                .selectRole(value),
            onReadChanged: (domain, value) => ref
                .read(aclMemberDetailsControllerProvider(params).notifier)
                .setReadPermission(domain, value),
            onWriteChanged: (domain, value) => ref
                .read(aclMemberDetailsControllerProvider(params).notifier)
                .setWritePermission(domain, value),
            onSave: () => _saveChanges(params),
            onRevoke: () => _revokeAccess(params, state.member),
            onLeave: () => _leaveAccess(params, state.member),
            onOwnerTransferPressed: () =>
                _showOwnerTransferDialog(params, state.member),
            onMessageTap: !PawlyFeatureFlags.chatEnabled ||
                    state.member.userId == state.me.userId
                ? null
                : () => openAclDirectChat(
                      context: context,
                      ref: ref,
                      petId: state.me.petId,
                      otherUserId: state.member.userId,
                    ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AclErrorView(
          title: 'Не удалось загрузить участника',
          message: 'Участник не найден или список доступа еще не обновился.',
          onRetry: () => ref
              .read(aclMemberDetailsControllerProvider(params).notifier)
              .reload(),
        ),
      ),
    );
  }

  Future<void> _saveChanges(AclMemberDetailsParams params) async {
    try {
      await ref
          .read(aclMemberDetailsControllerProvider(params).notifier)
          .saveChanges();
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: 'Права участника обновлены.',
        tone: PawlySnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: aclErrorMessage(error, 'Не удалось обновить участника.'),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  Future<void> _revokeAccess(
    AclMemberDetailsParams params,
    AclMember member,
  ) async {
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

    try {
      await ref
          .read(aclMemberDetailsControllerProvider(params).notifier)
          .revokeAccess();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: aclErrorMessage(error, 'Не удалось отозвать доступ.'),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  Future<void> _showOwnerTransferDialog(
    AclMemberDetailsParams params,
    AclMember member,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Передать роль владельца?'),
            content: Text(
              'После подтверждения ${member.displayName} станет основным владельцем питомца.',
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

    try {
      await ref
          .read(aclMemberDetailsControllerProvider(params).notifier)
          .transferOwnership();
      ref.invalidate(activePetDetailsControllerProvider(params.petId));
      await ref.read(petsControllerProvider.notifier).refreshAfterPetMutation();
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: '${member.displayName} теперь основной владелец питомца.',
        tone: PawlySnackBarTone.success,
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: aclErrorMessage(
          error,
          'Не удалось передать роль владельца.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  Future<void> _leaveAccess(
    AclMemberDetailsParams params,
    AclMember member,
  ) async {
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

    try {
      await ref
          .read(aclMemberDetailsControllerProvider(params).notifier)
          .leaveAccess();
      await ref.read(activePetControllerProvider.notifier).clear();
      ref.invalidate(activePetDetailsControllerProvider(params.petId));
      await ref.read(petsControllerProvider.notifier).reload();
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message:
            '${member.displayName} больше не участвует в уходе за питомцем.',
        tone: PawlySnackBarTone.success,
      );
      context.goNamed('pets');
    } catch (error) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: aclErrorMessage(
          error,
          'Не удалось выйти из ухода за питомцем.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }
}
