import 'package:flutter/material.dart';

class ChatInboxPage extends StatelessWidget {
  const ChatInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сообщения'),
      ),
      body: const Center(
        child: Text('Chat inbox is not implemented yet.'),
      ),
    );
  }
}
