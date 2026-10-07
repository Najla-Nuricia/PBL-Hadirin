import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
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
            _buildHeader(context, colorScheme),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 48),
                child: Column(
                  children: [
                    const Spacer(),
                    _buildPasswordField(
                      colorScheme: colorScheme,
                      label: 'Kata Sandi Baru',
                      hint: 'Masukkan kata sandi',
                      isVisible: _isNewPasswordVisible,
                      onVisibilityChanged: (value) {
                        setState(() => _isNewPasswordVisible = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      colorScheme: colorScheme,
                      label: 'Konfirmasi Kata Sandi Baru',
                      hint: 'Enter your mobile number',
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

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
  return Container(
    color: colorScheme.surface,
    child: SizedBox(
      height: 52,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/mhs/beranda'),
            icon: const Icon(Icons.chevron_left),
            color: colorScheme.onSurfaceVariant,
            tooltip: 'Kembali',
          ),
          Text(
            'Ubah Kata Sandi',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
  }

  Widget _buildPasswordField({
    required ColorScheme colorScheme,
    required String label,
    required String hint,
    required bool isVisible,
    required ValueChanged<bool> onVisibilityChanged,
  }) {
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
                fontSize: 14,
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

