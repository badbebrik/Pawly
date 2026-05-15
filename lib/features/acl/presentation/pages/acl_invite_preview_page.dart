import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../auth/controllers/auth_dependencies.dart';
import '../../../pets/controllers/active_pet_controller.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../controllers/acl_invite_preview_controller.dart';
import '../../shared/formatters/acl_error_formatters.dart';
import '../../shared/widgets/acl_error_view.dart';
import '../widgets/acl_invite_preview_content.dart';

class AclInvitePreviewPage extends ConsumerWidget {
  const AclInvitePreviewPage({
    required this.token,
    super.key,
  });

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return PawlyScreenScaffold(
        title: 'Приглашение',
        body: const AclErrorView(
          title: 'Ссылка приглашения недействительна',
          message: 'В ссылке отсутствует токен приглашения.',
        ),
      );
    }

    final state = ref.watch(
      aclInvitePreviewControllerProvider(normalizedToken),
    );

    return PawlyScreenScaffold(
      title: 'Приглашение',
      body: state.when(
        data: (value) => AclInvitePreviewContent(
          state: value,
          onAccept: () => _acceptInvite(context, ref, normalizedToken),
          onClose: () => _closePreview(context),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AclErrorView(
          title: 'Не удалось открыть приглашение',
          message: aclErrorMessage(
            error,
            'Проверьте ссылку или попробуйте открыть приглашение позже.',
          ),
          onRetry: () => ref
              .read(
                aclInvitePreviewControllerProvider(normalizedToken).notifier,
              )
              .reload(),
        ),
      ),
    );
  }

  Future<void> _acceptInvite(
    BuildContext context,
    WidgetRef ref,
    String token,
  ) async {
    final currentUserId = await ref.read(currentUserIdProvider.future);
    if (currentUserId == null || currentUserId.isEmpty) {
      if (!context.mounted) {
        return;
      }
      final redirectLocation = Uri(
        path: AppRoutes.aclInvitePreview,
        queryParameters: <String, String>{'token': token},
      ).toString();
      context.push(
        Uri(
          path: AppRoutes.login,
          queryParameters: <String, String>{'redirect': redirectLocation},
        ).toString(),
      );
      return;
    }

    try {
      final response = await ref
          .read(aclInvitePreviewControllerProvider(token).notifier)
          .accept();
      await ref.read(petsControllerProvider.notifier).reload();
      await ref
          .read(activePetControllerProvider.notifier)
          .selectPet(response.petId);
      if (!context.mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: 'Вы присоединились как ${response.roleTitle}.',
        tone: PawlySnackBarTone.success,
      );
      context.goNamed('pets');
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: aclErrorMessage(
          error,
          'Не удалось присоединиться к питомцу по приглашению.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  void _closePreview(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.pets);
  }
}
