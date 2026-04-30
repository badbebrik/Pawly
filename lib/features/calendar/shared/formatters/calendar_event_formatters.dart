import 'package:flutter/material.dart';

IconData calendarItemIcon(String type) {
  return switch (type) {
    'VET_VISIT' => Icons.local_hospital_rounded,
    'VACCINATION' => Icons.vaccines_rounded,
    'PROCEDURE' => Icons.medical_services_rounded,
    'LOG_TYPE' => Icons.list_alt_rounded,
    'MANUAL' => Icons.notifications_none_rounded,
    _ => Icons.event_note_rounded,
  };
}

String calendarItemTypeLabel(String type) {
  return switch (type) {
    'VET_VISIT' => 'Визит',
    'VACCINATION' => 'Вакцинация',
    'PROCEDURE' => 'Процедура',
    'LOG_TYPE' => 'Запись',
    'MANUAL' => 'Напоминание',
    _ => type,
  };
}
