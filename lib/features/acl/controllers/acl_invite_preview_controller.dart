import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/acl_invite_preview.dart';
import '../shared/mappers/acl_invite_preview_mapper.dart';
import '../states/acl_invite_preview_state.dart';
import 'acl_dependencies.dart';

final aclInvitePreviewControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AclInvitePreviewController, AclInvitePreviewState, String>(
  AclInvitePreviewController.new,
);

class AclInvitePreviewController extends AsyncNotifier<AclInvitePreviewState> {
  AclInvitePreviewController(this._token);

  final String _token;

  @override
  Future<AclInvitePreviewState> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<AclAcceptedInvite> accept() async {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Приглашение еще не загружено.');
    }

    state = AsyncData(current.copyWith(isSubmitting: true));

    try {
      final response =
          await ref.read(aclRepositoryProvider).acceptInviteByToken(
                _token,
              );
      state = AsyncData(current.copyWith(isSubmitting: false));
      return aclAcceptedInviteFromNetwork(response);
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<AclInvitePreviewState> _load() async {
    final preview = await ref.read(aclRepositoryProvider).previewInviteByToken(
          _token,
        );
    return AclInvitePreviewState.initial(
      preview: aclInvitePreviewFromNetwork(preview),
    );
  }
}
