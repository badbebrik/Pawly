import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../../controllers/home/health_home_controller.dart';
import '../../../states/home/health_home_state.dart';
import '../../widgets/home/health_home_widgets.dart';

class PetHealthHomePage extends ConsumerWidget {
  const PetHealthHomePage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(petHealthHomeProvider(petId));

    return PawlyScreenScaffold(
      title: 'Здоровье',
      body: stateAsync.when(
        data: (state) => HealthHomeView(
          state: state,
          onRetry: () => ref.invalidate(petHealthHomeProvider(petId)),
          onSectionTap: (type) => _handleSectionTap(context, type),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => HealthHomeErrorView(
          onRetry: () => ref.invalidate(petHealthHomeProvider(petId)),
        ),
      ),
    );
  }

  void _handleSectionTap(BuildContext context, PetHealthSectionType type) {
    final routeName = switch (type) {
      PetHealthSectionType.vetVisits => 'petVetVisits',
      PetHealthSectionType.vaccinations => 'petVaccinations',
      PetHealthSectionType.procedures => 'petProcedures',
      PetHealthSectionType.medicalRecords => 'petMedicalRecords',
    };

    context.pushNamed(
      routeName,
      pathParameters: <String, String>{'petId': petId},
    );
  }
}
