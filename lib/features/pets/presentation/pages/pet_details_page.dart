import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class PetDetailsPage extends StatelessWidget {
  const PetDetailsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return const PawlyScreenScaffold(
      title: 'Питомец',
      body: SizedBox.expand(),
    );
  }
}
