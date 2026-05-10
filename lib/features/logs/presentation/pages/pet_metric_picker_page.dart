import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/logs_controller.dart';
import '../../models/log_models.dart';
import '../../shared/utils/log_catalog_filters.dart';
import '../widgets/metric_picker_widgets.dart';

class PetMetricPickerPage extends ConsumerStatefulWidget {
  const PetMetricPickerPage({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<PetMetricPickerPage> createState() =>
      _PetMetricPickerPageState();
}

class _PetMetricPickerPageState extends ConsumerState<PetMetricPickerPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapAsync = ref.watch(
      petLogComposerBootstrapProvider(widget.petId),
    );

    return PawlyScreenScaffold(
      title: 'Выбрать показатель',
      floatingActionButton: PawlyAddActionButton(
        label: 'Новый показатель',
        tooltip: 'Создать показатель',
        onTap: _openCreateMetric,
      ),
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(context, bootstrap),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => MetricPickerErrorView(
          onRetry: () =>
              ref.invalidate(petLogComposerBootstrapProvider(widget.petId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LogsBootstrap bootstrap,
  ) {
    final systemMetrics = filterMetricsByName(
      metrics: bootstrap.systemMetrics,
      query: _searchQuery,
    );
    final customMetrics = filterMetricsByName(
      metrics: bootstrap.customMetrics,
      query: _searchQuery,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        PawlyTextField(
          controller: _searchController,
          hintText: 'Поиск по показателям',
          prefixIcon: const Icon(Icons.search_rounded),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        if (systemMetrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.md),
          MetricPickerSection(
            title: 'Системные',
            metrics: systemMetrics,
            onSelectMetric: _selectMetric,
          ),
        ],
        if (customMetrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          MetricPickerSection(
            title: 'Мои',
            metrics: customMetrics,
            onSelectMetric: _selectMetric,
          ),
        ],
      ],
    );
  }

  Future<void> _openCreateMetric() async {
    final createdMetricId = await context.pushNamed<String>(
      'petMetricCreate',
      pathParameters: <String, String>{'petId': widget.petId},
    );
    if (createdMetricId == null || !mounted) {
      return;
    }

    ref.invalidate(petLogComposerBootstrapProvider(widget.petId));
    try {
      await ref.read(petLogComposerBootstrapProvider(widget.petId).future);
    } catch (_) {}
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(createdMetricId);
  }

  void _selectMetric(String metricId) {
    Navigator.of(context).pop(metricId);
  }
}
