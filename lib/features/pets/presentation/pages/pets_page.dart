import 'package:flutter/material.dart';

class PetsPage extends StatelessWidget {
  const PetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Питомцы')),
      body: const SizedBox.expand(),
    );
  }
}
