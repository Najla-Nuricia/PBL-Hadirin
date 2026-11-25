import 'package:flutter_riverpod/flutter_riverpod.dart';

const _fallbackMessage = 'Periksa koneksi internet, lalu coba lagi.';

/// Pesan galat untuk pengguna.
///
/// `Exception('pesan')` dari lapisan data sudah berupa kalimat siap tampil,
/// jadi cukup awalannya yang dibuang. Galat lain (timeout, soket, parsing)
/// diganti kalimat umum supaya detail teknis tidak muncul di layar.
String lecturerErrorMessage(Object error) {
  const prefix = 'Exception: ';
  final text = error.toString();
  if (!text.startsWith(prefix)) return _fallbackMessage;
  final message = text.substring(prefix.length).trim();
  return message.isEmpty ? _fallbackMessage : message;
}

extension LecturerAsyncValueX<T> on AsyncValue<T> {
  /// Apakah galat perlu ditampilkan sekarang.
  ///
  /// Riverpod mencoba ulang sendiri setelah gagal dan selama itu statusnya
  /// tetap `isLoading`. Galat ditampilkan sejak kegagalan pertama supaya
  /// layar tidak berhenti di kerangka tanpa penjelasan.
  bool get showsError => hasError && (retrying || !isLoading);
}
