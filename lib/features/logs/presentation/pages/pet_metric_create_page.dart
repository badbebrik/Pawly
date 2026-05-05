import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/log_metric_create_controller.dart';
import '../../controllers/logs_controller.dart';
import '../../models/log_constants.dart';
import '../../shared/validators/log_catalog_validator.dart';
import '../widgets/metric_create_widgets.dart';

class PetMetricCreatePage extends ConsumerStatefulWidget {
  const PetMetricCreatePage({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<PetMetricCreatePage> createState() =>
      _PetMetricCreatePageState();
}

class _PetMetricCreatePageState extends ConsumerState<PetMetricCreatePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  String _inputKind = LogMetricInputKind.numeric;

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
    final isSubmitting = ref.watch(
      logMetricCreateControllerProvider(widget.petId).select(
        (value) => value.asData?.value.isSubmitting ?? false,
      ),
    );

    return PawlyScreenScaffold(
      title: 'Новый показатель',
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(
          context,
          bootstrap.canWrite,
          isSubmitting: isSubmitting,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => MetricCreateErrorView(
          onRetry: () =>
              ref.invalidate(petLogComposerBootstrapProvider(widget.petId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool canWrite, {
    required bool isSubmitting,
  }) {
    final canSubmit = canWrite && !isSubmitting;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        MetricCreateSection(
          title: 'Название',
          child: PawlyTextField(
            controller: _nameController,
            hintText: 'Например, Вес',
            enabled: canSubmit,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        MetricCreateSection(
          title: 'Тип ввода',
          child: Wrap(
            spacing: PawlySpacing.xs,
            runSpacing: PawlySpacing.xs,
            children: <Widget>[
              MetricKindPill(
                label: 'Число',
                isSelected: _inputKind == LogMetricInputKind.numeric,
                enabled: canSubmit,
                onTap: () => _selectKind(LogMetricInputKind.numeric),
              ),
              MetricKindPill(
                label: 'Шкала',
                isSelected: _inputKind == LogMetricInputKind.scale,
                enabled: canSubmit,
                onTap: () => _selectKind(LogMetricInputKind.scale),
              ),
              MetricKindPill(
                label: 'Да / Нет',
                isSelected: _inputKind == LogMetricInputKind.boolean,
                enabled: canSubmit,
                onTap: () => _selectKind(LogMetricInputKind.boolean),
              ),
            ],
          ),
        ),
        if (_inputKind != LogMetricInputKind.boolean) ...<Widget>[
          const SizedBox(height: PawlySpacing.md),
          MetricCreateSection(
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
                  _inputKind == LogMetricInputKind.scale
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
          const MetricCreateInlineMessage(
            title: 'Нет доступа',
            message:
                'У вас нет прав на создание показателей для этого питомца.',
          ),
        ],
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: isSubmitting ? 'Сохраняем...' : 'Создать показатель',
          onPressed: canSubmit ? _submit : null,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final validation = validateLogMetricForm(
      name: _nameController.text,
      inputKind: _inputKind,
      unitCode: _unitController.text,
      minValue: _minController.text,
      maxValue: _maxController.text,
    );
    if (!validation.isValid) {
      _showError(validation.errorMessage!);
      return;
    }

    try {
      final metricId = await ref
          .read(logMetricCreateControllerProvider(widget.petId).notifier)
          .submit(validation.form!);

      if (metricId == null || !mounted) {
        return;
      }
      Navigator.of(context).pop(metricId);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Не удалось создать показатель.',
      );
    }
  }

  void _showError(String message) {
    showPawlySnackBar(
      context,
      message: message,
      tone: PawlySnackBarTone.error,
    );
  }

  void _selectKind(String value) {
    if (_inputKind == value) {
      return;
    }
    setState(() {
      _inputKind = value;
      if (_inputKind == LogMetricInputKind.boolean) {
        _unitController.clear();
        _minController.clear();
        _maxController.clear();
      }
    });
  }
}
