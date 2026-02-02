import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/catalog_cache_models.dart';
import '../../data/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final api = ref.watch(catalogApiClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);

  return CatalogRepository(api: api, storage: storage);
});

final catalogSyncProvider = FutureProvider<CatalogSnapshot>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.syncCatalog();
});
