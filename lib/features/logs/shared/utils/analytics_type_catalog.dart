import '../../models/log_models.dart';
import 'log_type_utils.dart';

class AnalyticsTypeCatalog {
  const AnalyticsTypeCatalog({required this.sections, required this.byId});

  final List<AnalyticsTypeSection> sections;
  final Map<String, LogTypeItem> byId;

  factory AnalyticsTypeCatalog.fromBootstrap(LogsBootstrap? bootstrap) {
    if (bootstrap == null) {
      return const AnalyticsTypeCatalog(
        sections: <AnalyticsTypeSection>[],
        byId: <String, LogTypeItem>{},
      );
    }

    final groups = groupedBootstrapLogTypes(bootstrap);

    return AnalyticsTypeCatalog(
      sections: <AnalyticsTypeSection>[
        if (groups.recent.isNotEmpty)
          AnalyticsTypeSection(title: 'Недавние', items: groups.recent),
        if (groups.system.isNotEmpty)
          AnalyticsTypeSection(title: 'Системные', items: groups.system),
        if (groups.custom.isNotEmpty)
          AnalyticsTypeSection(title: 'Мои', items: groups.custom),
      ],
      byId: <String, LogTypeItem>{
        for (final type in groups.all) type.id: type,
      },
    );
  }

  bool get isEmpty => byId.isEmpty;

  List<LogTypeItem> resolveSelected(Iterable<String> ids) {
    final selected = <LogTypeItem>[];
    for (final id in ids) {
      final type = byId[id];
      if (type != null) {
        selected.add(type);
      }
    }
    selected.sort((left, right) => left.name.compareTo(right.name));
    return selected;
  }

  List<AnalyticsTypeSection> filter(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return sections;
    }

    return sections
        .map(
          (section) => AnalyticsTypeSection(
            title: section.title,
            items: section.items
                .where(
                  (item) => item.name.toLowerCase().contains(normalizedQuery),
                )
                .toList(growable: false),
          ),
        )
        .where((section) => section.items.isNotEmpty)
        .toList(growable: false);
  }
}

class AnalyticsTypeSection {
  const AnalyticsTypeSection({required this.title, required this.items});

  final String title;
  final List<LogTypeItem> items;
}
