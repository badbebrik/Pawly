String aclInviteMetaLabel(DateTime? expiresAt) {
  return expiresAt == null
      ? 'Без срока действия'
      : 'До ${aclInviteShortDate(expiresAt)}';
}

String aclInviteShortDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.${value.year}';
}

String aclInviteExpiryLabel(DateTime value) {
  final date = aclInviteShortDate(value);
  final time = '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
  return '$date в $time';
}
