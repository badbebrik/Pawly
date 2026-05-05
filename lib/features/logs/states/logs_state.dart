import '../models/log_models.dart';

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

  final LogsBootstrap bootstrap;
  final List<LogListItem> logs;
  final LogsFacets? facets;
  final String? nextCursor;
  final String searchQuery;
  final Set<String> selectedTypeIds;
  final String? selectedSource;
  final bool withAttachmentsOnly;
  final bool withMetricsOnly;
  final String sort;
  final bool isLoadingMore;

  PetLogsState copyWith({
    LogsBootstrap? bootstrap,
    List<LogListItem>? logs,
    LogsFacets? facets,
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
