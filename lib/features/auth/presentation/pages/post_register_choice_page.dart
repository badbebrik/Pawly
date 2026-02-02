import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';

class PostRegisterChoicePage extends StatelessWidget {
  const PostRegisterChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Почта подтверждена')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: PawlySpacing.lg),
              Text(
                'Хотите создать карточку питомца сейчас?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: PawlySpacing.sm),
              Text(
                'Можно создать питомца прямо сейчас или пропустить и сделать это позже.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              PawlyButton(
                label: 'Создать питомца сейчас',
                onPressed: () => context.go(AppRoutes.petCreate),
              ),
              const SizedBox(height: PawlySpacing.sm),
              PawlyButton(
                label: 'Пропустить',
                variant: PawlyButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
