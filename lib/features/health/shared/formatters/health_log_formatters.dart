import '../../models/health_models.dart';
import '../../../logs/models/log_constants.dart';
import '../../../logs/models/log_models.dart';
import 'health_display_formatters.dart';

String formatHealthRelatedLogSubtitle(RelatedLog log) {
  final parts = <String>[
    if (formatHealthDateTimeOrNull(log.occurredAt) case final date?) date,
    if (nonEmptyHealthText(log.descriptionPreview) case final preview?) preview,
    formatHealthLogSourceLabel(log.source),
  ];
  return parts.join(' · ');
}

String formatHealthLogListItemSubtitle(LogListItem log) {
  final parts = <String>[
    if (formatHealthDateTimeOrNull(log.occurredAt) case final date?) date,
    if (nonEmptyHealthText(log.descriptionPreview) case final preview?) preview,
    formatHealthLogSourceLabel(log.source),
  ];
  return parts.join(' · ');
}

String formatHealthLogSourceLabel(String source) {
  return switch (source) {
    LogSource.user => 'Журнал',
    LogSource.health => 'Медраздел',
    _ => source,
  };
}
