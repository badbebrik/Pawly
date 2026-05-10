import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/log_constants.dart';
import '../models/log_models.dart';
import '../states/logs_state.dart';
import 'logs_dependencies.dart';

final petLogsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetLogsController, PetLogsState, String>(
  PetLogsController.new,
);

final petLogComposerBootstrapProvider = FutureProvider.autoDispose
    .family<LogsBootstrap, String>((ref, petId) async {
  return ref.read(logsRepositoryProvider).getLogsBootstrap(petId);
});

class PetLogsController extends AsyncNotifier<PetLogsState> {
  PetLogsController(this._petId);

  final String _petId;

  @override
  Future<PetLogsState> build() async {
    final bootstrap = await ref.read(logsRepositoryProvider).getLogsBootstrap(
          _petId,
        );
    final response = await ref.read(logsRepositoryProvider).listLogs(
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
      sort: LogSort.occurredAtDesc,
      isLoadingMore: false,
    );
  }

  Future<void> reload() async {
    final previous = state.asData?.value;
    state = const AsyncLoading();
    try {
      final bootstrap = previous?.bootstrap ??
          await ref.read(logsRepositoryProvider).getLogsBootstrap(_petId);
      final response = await ref.read(logsRepositoryProvider).listLogs(
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
    await _reloadLogsSafely();
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
    await _reloadLogsSafely();
  }

  Future<void> setTypeFilters(Set<String> typeIds) async {
    final current = state.asData?.value;
    if (current == null) return;
    state =
        AsyncData(current.copyWith(selectedTypeIds: Set<String>.from(typeIds)));
    await _reloadLogsSafely();
  }

  Future<void> setSourceFilter(String? value) async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
          selectedSource: value, clearSelectedSource: value == null),
    );
    await _reloadLogsSafely();
  }

  Future<void> setWithAttachmentsOnly(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(withAttachmentsOnly: value));
    await _reloadLogsSafely();
  }

  Future<void> setWithMetricsOnly(bool value) async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(withMetricsOnly: value));
    await _reloadLogsSafely();
  }

  Future<void> setSort(String value) async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(sort: value));
    await _reloadLogsSafely();
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        current.isLoadingMore ||
        current.nextCursor == null) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final response = await ref.read(logsRepositoryProvider).listLogs(
            _petId,
            query: _query(base: current, cursor: current.nextCursor),
          );
      state = AsyncData(
        current.copyWith(
          logs: <LogListItem>[
            ...current.logs,
            ...response.items,
          ],
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

    final response = await ref.read(logsRepositoryProvider).listLogs(
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

  Future<void> _reloadLogsSafely() async {
    try {
      await _reloadLogs();
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  LogsQuery _query({PetLogsState? base, String? cursor}) {
    return LogsQuery(
      cursor: cursor,
      searchQuery: base?.searchQuery,
      typeIds:
          base?.selectedTypeIds.toList(growable: false) ?? const <String>[],
      source: base?.selectedSource,
      hasAttachments: base?.withAttachmentsOnly == true ? true : null,
      hasMetrics: base?.withMetricsOnly == true ? true : null,
      sort: base?.sort ?? LogSort.occurredAtDesc,
      includeFacets: cursor == null,
    );
  }

  PetLogsState _emptyState(LogsBootstrap bootstrap) {
    return PetLogsState(
      bootstrap: bootstrap,
      logs: const <LogListItem>[],
      facets: null,
      nextCursor: null,
      searchQuery: '',
      selectedTypeIds: <String>{},
      selectedSource: null,
      withAttachmentsOnly: false,
      withMetricsOnly: false,
      sort: LogSort.occurredAtDesc,
      isLoadingMore: false,
    );
  }
}
