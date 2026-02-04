import 'package:flutter/material.dart';

class PetDetailsPage extends StatelessWidget {
  const PetDetailsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Питомец')),
      body: const SizedBox.expand(),
    );
  }
}
