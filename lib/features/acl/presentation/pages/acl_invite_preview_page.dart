import 'package:flutter/material.dart';

class AclInvitePreviewPage extends StatelessWidget {
  const AclInvitePreviewPage({
    required this.token,
    super.key,
  });

  final String token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Приглашение к питомцу')),
      body: Center(
        child: Text('Preview token: $token'),
      ),
    );
  }
}
