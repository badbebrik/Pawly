import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/pets_controller.dart';
import '../../models/pet_list_entry.dart';
import '../widgets/active_pet_view.dart';

class PetDetailsPage extends ConsumerWidget {
  const PetDetailsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsState = ref.watch(petsControllerProvider).asData?.value;

    return PawlyScreenScaffold(
      title: 'Питомец',
      body: ActivePetView(
        petId: petId,
        entry: _petListEntryById(petsState?.items ?? const <PetListEntry>[]),
      ),
    );
  }

  PetListEntry? _petListEntryById(List<PetListEntry> items) {
    for (final item in items) {
      if (item.id == petId) {
        return item;
      }
    }
    return null;
  }
}
