import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/log_models.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/health_repository.dart';
import '../../data/health_repository_models.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final healthApiClient = ref.watch(healthApiClientProvider);
  return HealthRepository(healthApiClient: healthApiClient);
});

final petLogsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetLogsController, PetLogsState, String>(
  PetLogsController.new,
);

final petLogDetailsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetLogDetailsController, LogEntry, PetLogRef>(
  PetLogDetailsController.new,
);

final petLogComposerBootstrapProvider =
    FutureProvider.autoDispose.family<LogComposerBootstrapResponse, String>((
      ref,
      petId,
    ) {
      return ref.read(healthRepositoryProvider).getLogsBootstrap(petId);
    });

class PetLogRef {
  const PetLogRef({
    required this.petId,
    required this.logId,
  });

  final String petId;
  final String logId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PetLogRef &&
            other.petId == petId &&
            other.logId == logId;
  }

  @override
  int get hashCode => Object.hash(petId, logId);
}

class PetLogsState {
  const PetLogsState({
    required this.bootstrap,
    required this.logs,
    required this.facets,
    required this.nextCursor,
    required this.searchQuery,
    required this.selectedTypeIds,
    required this.selectedSource,
    required this.withAttachmentsOnly,
    required this.withMetricsOnly,
    required this.sort,
    required this.isLoadingMore,
  });

  final LogComposerBootstrapResponse bootstrap;
  final List<LogCard> logs;
  final LogListFacets? facets;
  final String? nextCursor;
  final String searchQuery;
  final Set<String> selectedTypeIds;
  final String? selectedSource;
  final bool withAttachmentsOnly;
  final bool withMetricsOnly;
  final String sort;
  final bool isLoadingMore;

  PetLogsState copyWith({
    LogComposerBootstrapResponse? bootstrap,
    List<LogCard>? logs,
    LogListFacets? facets,
    String? nextCursor,
    String? searchQuery,
    Set<String>? selectedTypeIds,
    String? selectedSource,
    bool clearSelectedSource = false,
    bool? withAttachmentsOnly,
    bool? withMetricsOnly,
    String? sort,
    bool? isLoadingMore,
  }) {
    return PetLogsState(
      bootstrap: bootstrap ?? this.bootstrap,
      logs: logs ?? this.logs,
      facets: facets ?? this.facets,
      nextCursor: nextCursor ?? this.nextCursor,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTypeIds: selectedTypeIds ?? this.selectedTypeIds,
      selectedSource:
          clearSelectedSource ? null : (selectedSource ?? this.selectedSource),
      withAttachmentsOnly: withAttachmentsOnly ?? this.withAttachmentsOnly,
      withMetricsOnly: withMetricsOnly ?? this.withMetricsOnly,
      sort: sort ?? this.sort,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class PetLogsController extends AsyncNotifier<PetLogsState> {
  PetLogsController(this._petId);

  final String _petId;

  @override
  Future<PetLogsState> build() async {
    final bootstrap = await ref.read(healthRepositoryProvider).getLogsBootstrap(
          _petId,
        );
    final response = await ref.read(healthRepositoryProvider).listLogs(
          _petId,
          query: _query(),
        );

    return PetLogsState(
      bootstrap: bootstrap,
      logs: response.items,
      facets: response.facets,
      nextCursor: response.nextCursor,
      searchQuery: '',
      selectedTypeIds: <String>{},
      selectedSource: null,
      withAttachmentsOnly: false,
      withMetricsOnly: false,
      sort: 'occurred_at_desc',
      isLoadingMore: false,
    );
  }

  Future<void> reload() async {
    final previous = state.asData?.value;
    state = const AsyncLoading();
    try {
      final bootstrap = previous?.bootstrap ??
          await ref.read(healthRepositoryProvider).getLogsBootstrap(_petId);
      final response = await ref.read(healthRepositoryProvider).listLogs(
            _petId,
            query: _query(base: previous),
          );
      state = AsyncData(
        (previous ?? _emptyState(bootstrap)).copyWith(
          bootstrap: bootstrap,
          logs: response.items,
          facets: response.facets,
          nextCursor: response.nextCursor,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> setSearchQuery(String value) async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(searchQuery: value));
    await _reloadLogs();
  }

  Future<void> toggleTypeFilter(String typeId) async {
    final current = state.asData?.value;
    if (current == null) return;
    final next = Set<String>.from(current.selectedTypeIds);
    if (next.contains(typeId)) {
      next.remove(typeId);
    } else {
      next.add(typeId);
    }
    state = AsyncData(current.copyWith(selectedTypeIds: next));
    await _reloadLogs();
  }

  Future<void> setSourceFilter(String? value) async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(selectedSource: value, clearSelectedSource: value == null),
    );
    await _reloadLogs();
  }

  Future<void> setWithAttachmentsOnly(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(withAttachmentsOnly: value));
    await _reloadLogs();
  }

  Future<void> setWithMetricsOnly(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(withMetricsOnly: value));
    await _reloadLogs();
  }

  Future<void> setSort(String value) async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(sort: value));
    await _reloadLogs();
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || current.nextCursor == null) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final response = await ref.read(healthRepositoryProvider).listLogs(
            _petId,
            query: _query(base: current, cursor: current.nextCursor),
          );
      state = AsyncData(
        current.copyWith(
          logs: <LogCard>[...current.logs, ...response.items],
          facets: response.facets ?? current.facets,
          nextCursor: response.nextCursor,
          isLoadingMore: false,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> _reloadLogs() async {
    final current = state.asData?.value;
    if (current == null) return;

    final response = await ref.read(healthRepositoryProvider).listLogs(
          _petId,
          query: _query(base: current),
        );
    state = AsyncData(
      current.copyWith(
        logs: response.items,
        facets: response.facets,
        nextCursor: response.nextCursor,
        isLoadingMore: false,
      ),
    );
  }

  LogListQuery _query({PetLogsState? base, String? cursor}) {
    return LogListQuery(
      cursor: cursor,
      searchQuery: base?.searchQuery,
      typeIds: base?.selectedTypeIds.toList(growable: false) ?? const <String>[],
      source: base?.selectedSource,
      hasAttachments: base?.withAttachmentsOnly == true ? true : null,
      hasMetrics: base?.withMetricsOnly == true ? true : null,
      sort: base?.sort ?? 'occurred_at_desc',
      includeFacets: cursor == null,
    );
  }

  PetLogsState _emptyState(LogComposerBootstrapResponse bootstrap) {
    return PetLogsState(
      bootstrap: bootstrap,
      logs: const <LogCard>[],
      facets: null,
      nextCursor: null,
      searchQuery: '',
      selectedTypeIds: <String>{},
      selectedSource: null,
      withAttachmentsOnly: false,
      withMetricsOnly: false,
      sort: 'occurred_at_desc',
      isLoadingMore: false,
    );
  }
}

class PetLogDetailsController extends AsyncNotifier<LogEntry> {
  PetLogDetailsController(this._refValue);

  final PetLogRef _refValue;

  @override
  Future<LogEntry> build() {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<LogEntry> _load() {
    return ref
        .read(healthRepositoryProvider)
        .getLog(_refValue.petId, _refValue.logId);
  }
}
