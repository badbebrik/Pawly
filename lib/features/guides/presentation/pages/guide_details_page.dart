import 'package:flutter/material.dart';

class GuideDetailsPage extends StatelessWidget {
  const GuideDetailsPage({
    required this.guideId,
    super.key,
  });

  final String guideId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Гайд')),
      body: const SizedBox.expand(),
    );
  }
}
