import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import 'pet_catalog_models.dart';
import 'pet_catalog_repository.dart';

final petCatalogRepositoryProvider = Provider<PetCatalogRepository>((ref) {
  final api = ref.watch(petDictionariesApiClientProvider);

  return PetCatalogRepository(
    api: api,
  );
});

final petCatalogProvider = FutureProvider.autoDispose<PetCatalog>((ref) async {
  final repo = ref.watch(petCatalogRepositoryProvider);
  return repo.getCatalog();
});
