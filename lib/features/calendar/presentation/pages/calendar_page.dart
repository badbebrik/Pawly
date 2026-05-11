import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/feature_flags.dart';
import '../../../../design_system/design_system.dart';
import '../../../chat/presentation/widgets/chat_app_bar_action.dart';
import '../../../pets/controllers/active_pet_controller.dart';
import '../../../pets/controllers/active_pet_details_controller.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../controllers/calendar_controller.dart';
import '../../models/calendar_day.dart';
import '../../models/calendar_occurrence_target.dart';
import '../../models/calendar_keys.dart';
import '../../shared/utils/calendar_occurrence_navigation.dart';
import '../widgets/calendar_date_header.dart';
import '../widgets/calendar_day_content.dart';
import '../widgets/calendar_picker_sheet.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarControllerProvider);
    final selectedDate = state.selectedDate;
    final petsState = ref.watch(petsControllerProvider).asData?.value;
    final petNamesById = <String, String>{
      for (final item in petsState?.items ?? const []) item.id: item.name,
    };
    final dayKey = CalendarDayKey(date: selectedDate);
    final dayAsync = ref.watch(calendarDayProvider(dayKey));

    return PawlyScreenScaffold(
      title: 'Календарь',
      actions: const <Widget>[
        if (PawlyFeatureFlags.chatEnabled) ChatAppBarAction(),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(calendarDayProvider(dayKey));
          ref.invalidate(calendarMarkersProvider);
          ref.invalidate(petsControllerProvider);
          try {
            await ref.read(calendarDayProvider(dayKey).future);
          } catch (_) {}
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            PawlySpacing.md,
            PawlySpacing.sm,
            PawlySpacing.md,
            PawlySpacing.xl,
          ),
          children: <Widget>[
            CalendarDateHeader(
              selectedDate: selectedDate,
              onSelectDate: _selectDate,
              onPickDate: _pickDate,
              onToday: _jumpToToday,
            ),
            const SizedBox(height: PawlySpacing.lg),
            dayAsync.when(
              data: (response) => CalendarDayContent(
                response: response,
                selectedDate: selectedDate,
                petNamesById: petNamesById,
                onOpenOccurrence: _openOccurrence,
              ),
              loading: () => const CalendarLoadingView(),
              error: (_, __) => CalendarErrorView(
                onRetry: () => ref.invalidate(calendarDayProvider(dayKey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selectedDate = ref.read(calendarControllerProvider).selectedDate;
    final now = DateTime.now();

    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return CalendarPickerSheet(
          selectedDate: selectedDate,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
        );
      },
    );

    if (!mounted || pickedDate == null) {
      return;
    }

    ref.read(calendarControllerProvider.notifier).setDate(pickedDate);
  }

  void _selectDate(DateTime value) {
    ref.read(calendarControllerProvider.notifier).setDate(value);
  }

  void _jumpToToday() {
    ref.read(calendarControllerProvider.notifier).jumpToToday();
  }

  Future<void> _openOccurrence(CalendarOccurrence occurrence) async {
    final petId = occurrence.petId;
    if (petId.isEmpty) {
      return;
    }

    await ref.read(activePetControllerProvider.notifier).selectPet(petId);
    ref.invalidate(activePetDetailsControllerProvider(petId));

    if (!mounted) {
      return;
    }

    openCalendarOccurrenceTarget(
      context,
      CalendarOccurrenceTarget.fromOccurrence(occurrence),
    );
  }
}
