import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../models/app_startup_destination.dart';

class SplashStatusView extends StatelessWidget {
  const SplashStatusView({
    required this.startupState,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<AppStartupDestination> startupState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return startupState.when(
      data: (_) => const _SessionCheckStatus(),
      loading: () => const _SessionCheckStatus(),
      error: (Object _, StackTrace __) {
        return Column(
          children: <Widget>[
            Text(
              'Не удалось запустить приложение',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: PawlySpacing.md),
            PawlyButton(
              label: 'Повторить',
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        );
      },
    );
  }
}

class _SessionCheckStatus extends StatelessWidget {
  const _SessionCheckStatus();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        Text(
          'Проверяем сессию...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
