import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pawly Home'),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(PawlySpacing.lg),
          child: Text(
            'Главный экран приложения',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.petCreate),
        tooltip: 'Создать питомца',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
