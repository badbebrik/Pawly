String? normalizePetColorHex(String input) {
  final value = input.trim().toUpperCase();
  final prepared = value.startsWith('#') ? value : '#$value';
  if (prepared.length != 7) return null;
  if (int.tryParse(prepared.substring(1), radix: 16) == null) return null;
  return prepared;
}
