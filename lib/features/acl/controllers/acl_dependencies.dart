import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/acl_repository.dart';

final aclRepositoryProvider = Provider<AclRepository>((ref) {
  final aclApiClient = ref.watch(aclApiClientProvider);
  return AclRepository(aclApiClient: aclApiClient);
});
