import 'package:flutter/material.dart';

class AclInviteDetailsPage extends StatelessWidget {
  const AclInviteDetailsPage({
    required this.petId,
    required this.inviteId,
    super.key,
  });

  final String petId;
  final String inviteId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Приглашение')),
      body: Center(
        child: Text('Приглашение $inviteId для питомца $petId'),
      ),
    );
  }
}
