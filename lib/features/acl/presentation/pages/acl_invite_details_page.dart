import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/acl_invite_details_controller.dart';
import '../../models/acl_invite_ref.dart';
import '../../shared/formatters/acl_error_formatters.dart';
import '../../shared/widgets/acl_error_view.dart';
import '../widgets/acl_invite_details_content.dart';

class AclInviteDetailsPage extends ConsumerWidget {
  const AclInviteDetailsPage({
    required this.petId,
    required this.inviteId,
    super.key,
  });

  final String petId;
  final String inviteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      aclInviteDetailsControllerProvider(
        AclInviteRef(petId: petId, inviteId: inviteId),
      ),
    );

    return PawlyScreenScaffold(
      title: 'Приглашение',
      actions: <Widget>[
        IconButton(
          onPressed: () => _editInvite(context),
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Редактировать',
        ),
        IconButton(
          onPressed: () => _deleteInvite(context, ref),
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'Удалить',
        ),
      ],
      body: state.when(
        data: (value) => AclInviteDetailsContent(state: value),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AclErrorView(
          title: 'Не удалось загрузить приглашение',
          message: 'Попробуйте открыть приглашение снова чуть позже.',
          onRetry: () => ref
              .read(
                aclInviteDetailsControllerProvider(
                  AclInviteRef(petId: petId, inviteId: inviteId),
                ).notifier,
              )
              .reload(),
        ),
      ),
    );
  }

  Future<void> _editInvite(BuildContext context) async {
    final nextInviteId = await context.pushNamed<String>(
      'aclInviteEdit',
      pathParameters: <String, String>{'petId': petId, 'inviteId': inviteId},
    );
    if (nextInviteId == null || !context.mounted) {
      return;
    }

    context.pushReplacementNamed(
      'aclInviteDetails',
      pathParameters: <String, String>{
        'petId': petId,
        'inviteId': nextInviteId,
      },
    );
  }

  Future<void> _deleteInvite(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Удалить приглашение?'),
            content: const Text(
              'Ссылка и код перестанут работать для новых участников.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Удалить'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(
            aclInviteDetailsControllerProvider(
              AclInviteRef(petId: petId, inviteId: inviteId),
            ).notifier,
          )
          .revokeInvite();
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: aclErrorMessage(error, 'Не удалось удалить приглашение.'),
        tone: PawlySnackBarTone.error,
      );
    }
  }
}
