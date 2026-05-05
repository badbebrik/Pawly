bool isMedicalReminderSource(String sourceType) {
  return sourceType == 'VET_VISIT' ||
      sourceType == 'VACCINATION' ||
      sourceType == 'PROCEDURE';
}

bool isUserManagedReminderSource(String sourceType) {
  return sourceType == 'MANUAL' ||
      sourceType == 'LOG_TYPE' ||
      sourceType == 'PET_EVENT';
}
