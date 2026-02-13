import 'package:flutter/material.dart';

class AclCreateInvitePage extends StatelessWidget {
  const AclCreateInvitePage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новое приглашение')),
      body: Center(
        child: Text('Создание приглашения для питомца $petId'),
      ),
    );
  }
}
