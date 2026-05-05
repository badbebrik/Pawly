import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/log_type_create_controller.dart';
import '../../controllers/logs_controller.dart';
import '../../models/log_models.dart';
import '../../shared/validators/log_catalog_validator.dart';
import '../widgets/log_type_create_widgets.dart';

class PetLogTypeCreatePage extends ConsumerStatefulWidget {
  const PetLogTypeCreatePage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetLogTypeCreatePage> createState() =>
      _PetLogTypeCreatePageState();
}

class _PetLogTypeCreatePageState extends ConsumerState<PetLogTypeCreatePage> {
  late final TextEditingController _nameController;
  final Map<String, bool> _selectedMetrics = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapAsync = ref.watch(
      petLogComposerBootstrapProvider(widget.petId),
    );
    final isSubmitting = ref.watch(
      logTypeCreateControllerProvider(widget.petId).select(
        (value) => value.asData?.value.isSubmitting ?? false,
      ),
    );

    return PawlyScreenScaffold(
      title: 'Новый тип записи',
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(
          context,
          bootstrap,
          isSubmitting: isSubmitting,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => TypeCreateErrorView(
          onRetry: () => ref.invalidate(
            petLogComposerBootstrapProvider(widget.petId),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LogsBootstrap bootstrap, {
    required bool isSubmitting,
  }) {
    final canSubmit = bootstrap.canWrite && !isSubmitting;

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        PawlyTextField(
          controller: _nameController,
          label: 'Название типа',
          hintText: 'Например, Контроль веса дома',
          enabled: canSubmit,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: PawlySpacing.lg),
        Text(
          'Показатели',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        Text(
          'Выберите, какие показатели будут доступны в этом типе записи.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: PawlySpacing.sm),
        PawlyButton(
          label: 'Выбрать показатель',
          onPressed: canSubmit ? _openMetricPicker : null,
          variant: PawlyButtonVariant.secondary,
          icon: Icons.add_rounded,
        ),
        if (_selectedMetrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.md),
          ..._selectedMetricEntries(bootstrap).map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: PawlySpacing.md),
              child: SelectedMetricCard(
                metric: entry.metric,
                isRequired: entry.isRequired,
                enabled: canSubmit,
                onRequiredChanged: (value) =>
                    _setMetricRequired(entry.metric.id, value),
                onRemove: () => _removeMetric(entry.metric.id),
              ),
            ),
          ),
        ],
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: isSubmitting ? 'Сохраняем...' : 'Создать тип',
          onPressed: canSubmit ? _submit : null,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }

  void _setMetricRequired(String metricId, bool isRequired) {
    setState(() {
      _selectedMetrics[metricId] = isRequired;
    });
  }

  void _removeMetric(String metricId) {
    setState(() {
      _selectedMetrics.remove(metricId);
    });
  }

  List<SelectedMetricEntry> _selectedMetricEntries(
    LogsBootstrap bootstrap,
  ) {
    final allMetrics = <String, LogMetricCatalogItem>{
      for (final metric in <LogMetricCatalogItem>[
        ...bootstrap.systemMetrics,
        ...bootstrap.customMetrics,
      ])
        metric.id: metric,
    };

    return _selectedMetrics.entries
        .map((entry) {
          final metric = allMetrics[entry.key];
          if (metric == null) {
            return null;
          }
          return SelectedMetricEntry(metric: metric, isRequired: entry.value);
        })
        .whereType<SelectedMetricEntry>()
        .toList(growable: false);
  }

  Future<void> _submit() async {
    final validation = validateLogTypeForm(
      name: _nameController.text,
      selectedMetrics: _selectedMetrics,
    );
    if (!validation.isValid) {
      _showError(validation.errorMessage!);
      return;
    }

    try {
      final typeId = await ref
          .read(logTypeCreateControllerProvider(widget.petId).notifier)
          .submit(validation.form!);

      if (typeId == null || !mounted) {
        return;
      }
      Navigator.of(context).pop(typeId);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Не удалось создать тип записи.',
      );
    }
  }

  Future<void> _openMetricPicker() async {
    final selectedMetricId = await context.pushNamed<String>(
      'petMetricPicker',
      pathParameters: <String, String>{'petId': widget.petId},
    );
    if (selectedMetricId == null || !mounted) {
      return;
    }

    ref.invalidate(petLogComposerBootstrapProvider(widget.petId));
    await ref.read(petLogComposerBootstrapProvider(widget.petId).future);
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedMetrics.putIfAbsent(selectedMetricId, () => false);
    });
  }

  void _showError(String message) {
    showPawlySnackBar(
      context,
      message: message,
      tone: PawlySnackBarTone.error,
    );
  }
}
