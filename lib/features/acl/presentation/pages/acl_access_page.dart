import 'package:flutter/material.dart';

class AclAccessPage extends StatelessWidget {
  const AclAccessPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Совместный доступ')),
      body: Center(
        child: Text('Экран доступа для питомца $petId'),
      ),
    );
  }
}
