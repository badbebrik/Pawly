String petRoleCaption(String rawTitle) {
  return 'Роль: ${petRoleTitle(rawTitle)}';
}

String petFallbackRoleTitle({required bool isOwner}) {
  return isOwner ? 'Владелец' : 'Участник';
}

String petRoleTitle(String rawTitle) {
  final normalized = rawTitle.trim();
  final upper = normalized.toUpperCase();

  return switch (upper) {
    'OWNER' => 'Владелец',
    'CO_OWNER' || 'CO-OWNER' => 'Совладелец',
    'VET' || 'VETERINARY' => 'Ветеринар',
    'PETSITTER' => 'Петситтер',
    'WALKER' => 'Выгульщик',
    _ => normalized,
  };
}
