import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../data/health_repository_models.dart';
import '../providers/health_controllers.dart';

class PetMetricCreatePage extends ConsumerStatefulWidget {
  const PetMetricCreatePage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetMetricCreatePage> createState() =>
      _PetMetricCreatePageState();
}

class _PetMetricCreatePageState extends ConsumerState<PetMetricCreatePage> {
  static const String _numericKind = 'NUMERIC';
  static const String _scaleKind = 'SCALE';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Новая метрика')),
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(context, bootstrap.permissions.logWrite),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _MetricCreateErrorView(
          onRetry: () => ref.invalidate(
            petLogComposerBootstrapProvider(widget.petId),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool canWrite) {
    final canSubmit = canWrite && !_isSubmitting;

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        PawlyTextField(
          controller: _nameController,
          label: 'Название метрики',
          hintText: 'Например, Вес',
          enabled: canSubmit,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: PawlySpacing.md),
        DropdownButtonFormField<String>(
          value: _inputKind,
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: _numericKind,
              child: Text('Число'),
            ),
            DropdownMenuItem<String>(
              value: _scaleKind,
              child: Text('Шкала'),
            ),
          ],
          onChanged: canSubmit
              ? (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _inputKind = value;
                  });
                }
              : null,
          decoration: const InputDecoration(labelText: 'Тип ввода'),
        ),
        const SizedBox(height: PawlySpacing.md),
        PawlyTextField(
          controller: _unitController,
          label: 'Единица измерения',
          hintText: 'кг, мл, баллы',
          enabled: canSubmit,
        ),
        const SizedBox(height: PawlySpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: PawlyTextField(
                controller: _minController,
                label: 'Минимум',
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
                label: 'Максимум',
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
              ? 'Для шкалы лучше задать оба значения диапазона.'
              : 'Диапазон можно оставить пустым.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (!canWrite) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          const PawlyCard(
            child: Text('У вас нет прав на создание метрик для этого питомца.'),
          ),
        ],
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: _isSubmitting ? 'Сохраняем...' : 'Создать метрику',
          onPressed: canSubmit ? _submit : null,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Укажи название метрики.');
      return;
    }

    final minValue = _parseNumber(_minController.text);
    final maxValue = _parseNumber(_maxController.text);

    if (_inputKind == _scaleKind && (minValue == null || maxValue == null)) {
      _showError('Для шкалы нужно указать минимум и максимум.');
      return;
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
              unitCode: _unitController.text.trim().isEmpty
                  ? null
                  : _unitController.text.trim(),
              minValue: minValue,
              maxValue: maxValue,
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
            : 'Не удалось создать метрику.',
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MetricCreateErrorView extends StatelessWidget {
  const _MetricCreateErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось подготовить создание метрики.'),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
