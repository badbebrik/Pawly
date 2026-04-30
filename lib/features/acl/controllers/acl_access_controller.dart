import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/mappers/acl_access_mapper.dart';
import '../states/acl_access_state.dart';
import 'acl_dependencies.dart';

final aclAccessControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AclAccessController, AclAccessState, String>(
  AclAccessController.new,
);

class AclAccessController extends AsyncNotifier<AclAccessState> {
  AclAccessController(this._petId);

  final String _petId;

  @override
  Future<AclAccessState> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<AclAccessState> _load() async {
    final bootstrap =
        await ref.read(aclRepositoryProvider).getBootstrap(_petId);
    return aclAccessStateFromNetwork(bootstrap);
  }
}
