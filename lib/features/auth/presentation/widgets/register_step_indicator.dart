import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/register_step.dart';

class RegisterStepIndicator extends StatelessWidget {
  const RegisterStepIndicator({required this.currentStep, super.key});

  final RegisterStep currentStep;

  @override
  Widget build(BuildContext context) {
    final currentIndex = currentStep.index;

    const labels = <String>['Имя', 'Email', 'Пароль', 'Код'];

    return Wrap(
      spacing: PawlySpacing.sm,
      runSpacing: PawlySpacing.xs,
      children: List<Widget>.generate(labels.length, (index) {
        final done = index < currentIndex;
        final active = index == currentIndex;

        return _RegisterDotStep(
          index: index + 1,
          active: active,
          done: done,
          label: labels[index],
        );
      }),
    );
  }
}

class _RegisterDotStep extends StatelessWidget {
  const _RegisterDotStep({
    required this.index,
    required this.active,
    required this.done,
    required this.label,
  });

  final int index;
  final bool active;
  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final background =
        done || active ? colorScheme.primary : colorScheme.primaryContainer;

    final foreground =
        done || active ? colorScheme.onPrimary : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.xs,
        vertical: PawlySpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            done ? '✓' : '$index',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                ),
          ),
          const SizedBox(width: PawlySpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                ),
          ),
        ],
      ),
    );
  }
}
