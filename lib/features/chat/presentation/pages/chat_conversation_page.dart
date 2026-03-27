import 'package:flutter/material.dart';

class ChatConversationPage extends StatelessWidget {
  const ChatConversationPage({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            Text('Chat conversation is not implemented yet.'),
      ),
    );
  }
}
