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
    barrierColor: const Color(0x66000000),
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

    return Dialog(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 21,
                  color: scheme.error,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Keluar dari akun?',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sesi mengajar $fullName berakhir. Masuk lagi dengan $email untuk melihat daftar presensi.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 8,
                  children: [
                    _DialogAction(
                      key: const ValueKey('lecturer-logout-cancel'),
                      label: 'Tetap di sini',
                      foreground: scheme.onSurfaceVariant,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    _DialogAction(
                      key: const ValueKey('lecturer-logout-confirm'),
                      label: 'Keluar',
                      foreground: scheme.onError,
                      background: scheme.error,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    super.key,
    required this.label,
    required this.foreground,
    required this.onPressed,
    this.background,
  });

  final String label;
  final Color foreground;
  final Color? background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: onPressed,
      style:
          TextButton.styleFrom(
            foregroundColor: foreground,
            backgroundColor: background,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ).copyWith(
            overlayColor: WidgetStatePropertyAll(
              background == null
                  ? scheme.onSurface.withValues(alpha: 0.06)
                  : scheme.onError.withValues(alpha: 0.16),
            ),
          ),
      child: Text(label),
    );
  }
}
