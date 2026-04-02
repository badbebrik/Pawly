import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/catalog_cache_models.dart';
import '../../data/pet_dictionaries_repository.dart';

final petDictionariesRepositoryProvider = Provider<PetDictionariesRepository>((
  ref,
) {
  final api = ref.watch(petDictionariesApiClientProvider);
  final sharedPreferences = ref.watch(sharedPreferencesServiceProvider);

  return PetDictionariesRepository(
    api: api,
    sharedPreferences: sharedPreferences,
  );
});

final petDictionariesSyncProvider =
    FutureProvider<CatalogSnapshot>((ref) async {
  final repo = ref.watch(petDictionariesRepositoryProvider);
  return repo.syncCatalog();
});
