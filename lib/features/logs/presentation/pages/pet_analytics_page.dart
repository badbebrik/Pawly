import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/analytics_controller.dart';
import '../../controllers/logs_controller.dart';
import '../../models/analytics_models.dart';
import '../../models/log_refs.dart';
import '../../shared/formatters/analytics_formatters.dart';
import '../../shared/utils/analytics_export.dart';
import '../../shared/utils/analytics_type_catalog.dart';
import '../../states/analytics_filter_state.dart';
import '../widgets/analytics_filter_widgets.dart';
import '../widgets/analytics_metric_picker_sheet.dart';
import '../widgets/analytics_metric_view.dart';
import '../widgets/analytics_state_views.dart';
import '../widgets/analytics_toolbar.dart';

class PetAnalyticsPage extends ConsumerStatefulWidget {
  const PetAnalyticsPage({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<PetAnalyticsPage> createState() => _PetAnalyticsPageState();
}

class _PetAnalyticsPageState extends ConsumerState<PetAnalyticsPage> {
  String? _selectedMetricId;
  String _range = '30d';
  DateTimeRange? _customDateRange;
  String? _dateFrom;
  String? _dateTo;
  final Set<String> _selectedTypeIds = <String>{};

  @override
  void initState() {
    super.initState();
    final resolvedRange = resolveAnalyticsPresetRange('30d');
    _dateFrom = resolvedRange.dateFrom;
    _dateTo = resolvedRange.dateTo;
  }

  @override
  Widget build(BuildContext context) {
    final typeIds = _selectedTypeIds.toList(growable: false)..sort();
    final metricsAsync = ref.watch(
      petAnalyticsMetricsProvider(
        PetAnalyticsMetricsRef(
          petId: widget.petId,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          typeIds: typeIds,
        ),
      ),
    );
    final bootstrapAsync = ref.watch(
      petLogComposerBootstrapProvider(widget.petId),
    );
    final typeCatalog = AnalyticsTypeCatalog.fromBootstrap(
      bootstrapAsync.asData?.value,
    );
    return PawlyScreenScaffold(
      title: 'Динамика',
      body: metricsAsync.when(
        data: (metrics) => _buildContent(
          context,
          metrics: metrics,
          typeCatalog: typeCatalog,
          isTypeCatalogLoading: bootstrapAsync.isLoading,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AnalyticsErrorView(
          onRetry: () {
            ref.invalidate(petAnalyticsMetricsProvider);
            ref.invalidate(petLogComposerBootstrapProvider(widget.petId));
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required List<AnalyticsMetricItem> metrics,
    required AnalyticsTypeCatalog typeCatalog,
    required bool isTypeCatalogLoading,
  }) {
    final typeIds = _selectedTypeIds.toList(growable: false)..sort();
    final selectedMetric = metrics.isEmpty
        ? null
        : metrics.firstWhere(
            (item) =>
                item.metricId == (_selectedMetricId ?? metrics.first.metricId),
            orElse: () => metrics.first,
          );

    if (metrics.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.sm,
          PawlySpacing.md,
          PawlySpacing.xl,
        ),
        children: <Widget>[
          AnalyticsCompactToolbar(
            metricLabel: 'Нет показателей',
            onPickMetric: null,
            onOpenFilters: () => _openFilters(typeCatalog),
            hasActiveFilters: _hasCustomFilters,
            activeFiltersSummary: _activeFiltersSummary(typeCatalog),
            isFiltersLoading: isTypeCatalogLoading,
          ),
          const SizedBox(height: PawlySpacing.md),
          AnalyticsEmptyState(
            hasTypeFilters: _selectedTypeIds.isNotEmpty,
            hasPeriodFilters: _dateFrom != null || _dateTo != null,
            onClearTypes: _selectedTypeIds.isEmpty ? null : _clearTypeFilters,
            onShowAllTime:
                (_dateFrom == null && _dateTo == null) ? null : _showAllTime,
          ),
        ],
      );
    }

    final seriesAsync = ref.watch(
      petMetricSeriesProvider(
        PetMetricSeriesRef(
          petId: widget.petId,
          metricId: selectedMetric!.metricId,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          typeIds: typeIds,
        ),
      ),
    );
    final loadedSeries = seriesAsync.asData?.value;
    final canExport = loadedSeries != null && loadedSeries.points.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        AnalyticsCompactToolbar(
          metricLabel: selectedMetric.metricName,
          onPickMetric: () => _pickMetric(metrics),
          onOpenFilters: () => _openFilters(typeCatalog),
          hasActiveFilters: _hasCustomFilters,
          activeFiltersSummary: _activeFiltersSummary(typeCatalog),
          isFiltersLoading: isTypeCatalogLoading,
          onExport: canExport
              ? () => _exportMetricSeries(selectedMetric, loadedSeries)
              : null,
        ),
        const SizedBox(height: PawlySpacing.md),
        seriesAsync.when(
          data: (series) => AnalyticsMetricView(
            summaryMetric: selectedMetric,
            series: series,
          ),
          loading: () => const AnalyticsLoadingBlock(),
          error: (_, __) => const AnalyticsInlineMessage(
            title: 'Не удалось загрузить график',
            message:
                'Попробуйте выбрать показатель ещё раз или обновить экран.',
          ),
        ),
      ],
    );
  }

  bool get _hasCustomFilters => _selectedTypeIds.isNotEmpty || _range != '30d';

  Future<void> _pickMetric(List<AnalyticsMetricItem> metrics) async {
    final nextMetricId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => AnalyticsMetricPickerSheet(
        metrics: metrics,
        selectedMetricId: _selectedMetricId ?? metrics.first.metricId,
      ),
    );
    if (nextMetricId == null) {
      return;
    }

    setState(() {
      _selectedMetricId = nextMetricId;
    });
  }

  Future<void> _openFilters(AnalyticsTypeCatalog typeCatalog) async {
    final nextFilters = await showModalBottomSheet<AnalyticsFilterState>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => AnalyticsFiltersSheet(
        initialState: AnalyticsFilterState(
          range: _range,
          customDateRange: _customDateRange,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          selectedTypeIds: _selectedTypeIds,
        ),
        typeCatalog: typeCatalog,
      ),
    );
    if (nextFilters == null) {
      return;
    }

    setState(() {
      _range = nextFilters.range;
      _customDateRange = nextFilters.customDateRange;
      _dateFrom = nextFilters.dateFrom;
      _dateTo = nextFilters.dateTo;
      _selectedTypeIds
        ..clear()
        ..addAll(nextFilters.selectedTypeIds);
    });
  }

  void _clearTypeFilters() {
    setState(() {
      _selectedTypeIds.clear();
    });
  }

  void _showAllTime() {
    setState(() {
      _range = 'all';
      _customDateRange = null;
      _dateFrom = null;
      _dateTo = null;
    });
  }

  String? _activeFiltersSummary(AnalyticsTypeCatalog catalog) {
    return analyticsActiveFiltersSummary(
      range: _range,
      customDateRange: _customDateRange,
      typeCatalog: catalog,
      selectedTypeIds: _selectedTypeIds,
    );
  }

  Future<void> _exportMetricSeries(
    AnalyticsMetricItem metric,
    MetricSeries series,
  ) async {
    if (series.points.isEmpty) {
      showPawlySnackBar(
        context,
        message: 'Нет данных для экспорта.',
        tone: PawlySnackBarTone.warning,
      );
      return;
    }

    try {
      final csv = buildAnalyticsMetricSeriesCsv(
        metric: metric,
        series: series,
      );
      final fileName = analyticsMetricSeriesExportFileName(metric);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final box = context.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        <XFile>[
          XFile.fromData(
            bytes,
            name: fileName,
            mimeType: analyticsCsvMimeType,
          ),
        ],
        fileNameOverrides: <String>[fileName],
        subject: 'Экспорт показателя ${metric.metricName}',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: 'Не удалось подготовить экспорт.',
        tone: PawlySnackBarTone.error,
      );
    }
  }
}
