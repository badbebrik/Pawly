import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/feature_flags.dart';
import '../../../../design_system/design_system.dart';
import '../../controllers/acl_access_controller.dart';
import '../../shared/utils/acl_chat_navigation.dart';
import '../../shared/widgets/acl_error_view.dart';
import '../widgets/acl_access_content.dart';

class AclAccessPage extends ConsumerWidget {
  const AclAccessPage({required this.petId, super.key});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessState = ref.watch(aclAccessControllerProvider(petId));

    return PawlyScreenScaffold(
      title: 'Участники',
      body: accessState.when(
        data: (state) => AclAccessContent(
          state: state,
          onMemberTap: (memberId) => context.pushNamed(
            'aclMemberDetails',
            pathParameters: <String, String>{
              'petId': petId,
              'memberId': memberId,
            },
          ),
          onCreateInvite: state.capabilities.membersWrite
              ? () => context.pushNamed(
                    'aclCreateInvite',
                    pathParameters: <String, String>{'petId': petId},
                  )
              : null,
          onInviteTap: (inviteId) => context.pushNamed(
            'aclInviteDetails',
            pathParameters: <String, String>{
              'petId': petId,
              'inviteId': inviteId,
            },
          ),
          onMessageTap: PawlyFeatureFlags.chatEnabled
              ? (otherUserId) => openAclDirectChat(
                    context: context,
                    ref: ref,
                    petId: state.me.petId,
                    otherUserId: otherUserId,
                  )
              : null,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AclErrorView(
          title: 'Не удалось загрузить доступ',
          message: 'Проверьте соединение или попробуйте снова чуть позже.',
          onRetry: () =>
              ref.read(aclAccessControllerProvider(petId).notifier).reload(),
        ),
      ),
    );
  }
}
