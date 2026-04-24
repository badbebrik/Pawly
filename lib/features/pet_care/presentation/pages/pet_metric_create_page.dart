import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../data/health_repository_models.dart';
import '../providers/health_controllers.dart';

class PetMetricCreatePage extends ConsumerStatefulWidget {
  const PetMetricCreatePage({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<PetMetricCreatePage> createState() =>
      _PetMetricCreatePageState();
}

class _PetMetricCreatePageState extends ConsumerState<PetMetricCreatePage> {
  static const String _numericKind = 'NUMERIC';
  static const String _scaleKind = 'SCALE';
  static const String _booleanKind = 'BOOLEAN';

  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  String _inputKind = _numericKind;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _unitController = TextEditingController();
    _minController = TextEditingController();
    _maxController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapAsync = ref.watch(
      petLogComposerBootstrapProvider(widget.petId),
    );

    return PawlyScreenScaffold(
      title: 'Новый показатель',
      body: bootstrapAsync.when(
        data: (bootstrap) =>
            _buildContent(context, bootstrap.permissions.logWrite),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _MetricCreateErrorView(
          onRetry: () =>
              ref.invalidate(petLogComposerBootstrapProvider(widget.petId)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool canWrite) {
    final canSubmit = canWrite && !_isSubmitting;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        _MetricCreateSection(
          title: 'Название',
          child: PawlyTextField(
            controller: _nameController,
            hintText: 'Например, Вес',
            enabled: canSubmit,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        _MetricCreateSection(
          title: 'Тип ввода',
          child: Wrap(
            spacing: PawlySpacing.xs,
            runSpacing: PawlySpacing.xs,
            children: <Widget>[
              _MetricKindPill(
                label: 'Число',
                isSelected: _inputKind == _numericKind,
                enabled: canSubmit,
                onTap: () => _selectKind(_numericKind),
              ),
              _MetricKindPill(
                label: 'Шкала',
                isSelected: _inputKind == _scaleKind,
                enabled: canSubmit,
                onTap: () => _selectKind(_scaleKind),
              ),
              _MetricKindPill(
                label: 'Да / Нет',
                isSelected: _inputKind == _booleanKind,
                enabled: canSubmit,
                onTap: () => _selectKind(_booleanKind),
              ),
            ],
          ),
        ),
        if (_inputKind != _booleanKind) ...<Widget>[
          const SizedBox(height: PawlySpacing.md),
          _MetricCreateSection(
            title: 'Единица и диапазон',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PawlyTextField(
                  controller: _unitController,
                  hintText: 'кг, мл, баллы',
                  enabled: canSubmit,
                ),
                const SizedBox(height: PawlySpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: PawlyTextField(
                        controller: _minController,
                        hintText: 'Минимум',
                        enabled: canSubmit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: PawlySpacing.md),
                    Expanded(
                      child: PawlyTextField(
                        controller: _maxController,
                        hintText: 'Максимум',
                        enabled: canSubmit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  _inputKind == _scaleKind
                      ? 'Для шкалы нужно задать оба значения диапазона.'
                      : 'Диапазон можно оставить пустым или задать одну границу.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
        if (!canWrite) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          const _MetricCreateInlineMessage(
            title: 'Нет доступа',
            message:
                'У вас нет прав на создание показателей для этого питомца.',
          ),
        ],
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: _isSubmitting ? 'Сохраняем...' : 'Создать показатель',
          onPressed: canSubmit ? _submit : null,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Укажите название показателя.');
      return;
    }

    final minValue = _parseNumber(_minController.text);
    final maxValue = _parseNumber(_maxController.text);
    final unitCode = _unitController.text.trim().isEmpty
        ? null
        : _unitController.text.trim();

    if (_inputKind == _scaleKind && (minValue == null || maxValue == null)) {
      _showError('Для шкалы нужно указать минимум и максимум.');
      return;
    }
    if (_inputKind == _booleanKind) {
      if (unitCode != null || minValue != null || maxValue != null) {
        _showError(
          'Для boolean единица измерения и диапазон должны быть пустыми.',
        );
        return;
      }
    }
    if (minValue != null && maxValue != null && minValue >= maxValue) {
      _showError('Минимум должен быть меньше максимума.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final metric = await ref.read(healthRepositoryProvider).createMetric(
            widget.petId,
            input: UpsertMetricInput(
              name: name,
              inputKind: _inputKind,
              unitCode: _inputKind == _booleanKind ? null : unitCode,
              minValue: _inputKind == _booleanKind ? null : minValue,
              maxValue: _inputKind == _booleanKind ? null : maxValue,
            ),
          );
      ref.invalidate(petLogComposerBootstrapProvider(widget.petId));

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(metric.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Не удалось создать показатель.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  double? _parseNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectKind(String value) {
    if (_inputKind == value) {
      return;
    }
    setState(() {
      _inputKind = value;
      if (_inputKind == _booleanKind) {
        _unitController.clear();
        _minController.clear();
        _maxController.clear();
      }
    });
  }
}

class _MetricCreateSection extends StatelessWidget {
  const _MetricCreateSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: PawlySpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricKindPill extends StatelessWidget {
  const _MetricKindPill({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(PawlyRadius.pill),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.84),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.md,
          vertical: PawlySpacing.xs,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MetricCreateInlineMessage extends StatelessWidget {
  const _MetricCreateInlineMessage({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: PawlySpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCreateErrorView extends StatelessWidget {
  const _MetricCreateErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Не удалось подготовить создание показателя',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Попробуйте открыть форму снова через несколько секунд.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyButton(
                  label: 'Повторить',
                  onPressed: onRetry,
                  variant: PawlyButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
