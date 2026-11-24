import 'package:flutter/material.dart';

/// Menampilkan konfirmasi keluar akun dosen.
///
/// Mengembalikan `true` hanya bila dosen menekan tombol keluar.
Future<bool> showLecturerLogoutDialog(
  BuildContext context, {
  required String fullName,
  required String email,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _LecturerLogoutDialog(fullName: fullName, email: email),
  );
  return confirmed ?? false;
}

class _LecturerLogoutDialog extends StatelessWidget {
  const _LecturerLogoutDialog({required this.fullName, required this.email});

  final String fullName;
  final String email;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Keluar dari akun?'),
      content: Text(
        'Sesi mengajar $fullName berakhir. Masuk lagi dengan $email untuk '
        'melihat daftar presensi.',
      ),
      actions: [
        TextButton(
          key: const ValueKey('lecturer-logout-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Tetap di sini'),
        ),
        FilledButton(
          key: const ValueKey('lecturer-logout-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Keluar'),
        ),
      ],
    );
  }
}
