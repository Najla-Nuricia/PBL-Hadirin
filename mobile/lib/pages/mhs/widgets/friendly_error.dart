final _exceptionPrefix = RegExp(r'^Exception:\s*');
final _technicalDetail = RegExp(
  r"(Exception|Error)\b|is not a subtype|Null check operator|^type '",
);

/// Pesan galat yang layak dibaca pengguna. Pesan dari server dipakai apa
/// adanya; galat teknis (nama kelas exception Dart) diganti [fallback].
String friendlyError(Object error, {required String fallback}) {
  final message = error.toString().replaceFirst(_exceptionPrefix, '').trim();
  if (message.isEmpty || _technicalDetail.hasMatch(message)) return fallback;
  return message;
}
