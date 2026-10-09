import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/lecturer_route_paths.dart';

class LecturerChangePasswordPage extends StatefulWidget {
  const LecturerChangePasswordPage({super.key});

  @override
  State<LecturerChangePasswordPage> createState() =>
      _LecturerChangePasswordPageState();
}

class _LecturerChangePasswordPageState
    extends State<LecturerChangePasswordPage> {
  bool _isNewPasswordVisible = false;
  bool _isConfirmationVisible = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: colorScheme.surface,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () =>
                          context.go(LecturerRoutePaths.profil),
                      icon: const Icon(Icons.arrow_back_ios_new),
                      iconSize: 19,
                      color: colorScheme.primary,
                      tooltip: 'Kembali',
                    ),
                  ),
                  Text(
                    'Ubah Kata Sandi',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 48),
                child: Column(
                  children: [
                    const Spacer(),
                    _LecturerPasswordField(
                      label: 'Kata Sandi Baru',
                      hint: 'Masukkan kata sandi',
                      isVisible: _isNewPasswordVisible,
                      onVisibilityChanged: (value) {
                        setState(() => _isNewPasswordVisible = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _LecturerPasswordField(
                      label: 'Konfirmasi Kata Sandi Baru',
                      hint: 'Masukkan ulang kata sandi',
                      isVisible: _isConfirmationVisible,
                      onVisibilityChanged: (value) {
                        setState(() => _isConfirmationVisible = value);
                      },
                    ),
                    const Spacer(flex: 11),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LecturerPasswordField extends StatelessWidget {
  const _LecturerPasswordField({
    required this.label,
    required this.hint,
    required this.isVisible,
    required this.onVisibilityChanged,
  });

  final String label;
  final String hint;
  final bool isVisible;
  final ValueChanged<bool> onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 38,
          child: TextField(
            obscureText: !isVisible,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 11),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 38,
                minHeight: 38,
              ),
              suffixIcon: IconButton(
                onPressed: () => onVisibilityChanged(!isVisible),
                padding: EdgeInsets.zero,
                icon: Icon(
                  isVisible ? Icons.visibility_outlined : Icons.visibility_off,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
                tooltip: isVisible
                    ? 'Sembunyikan kata sandi'
                    : 'Tampilkan kata sandi',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colorScheme.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
