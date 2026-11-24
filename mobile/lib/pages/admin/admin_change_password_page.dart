import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/admin_auth_repository.dart';

/// Ubah kata sandi admin — mengikuti pola halaman Ubah Kata Sandi mahasiswa.
class AdminChangePasswordPage extends StatefulWidget {
  const AdminChangePasswordPage({super.key});

  @override
  State<AdminChangePasswordPage> createState() =>
      _AdminChangePasswordPageState();
}

class _AdminChangePasswordPageState extends State<AdminChangePasswordPage> {
  static const _minimumPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    var changed = false;
    String? errorMessage;
    try {
      changed = await adminAuthRepository.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
        confirmPassword: _confirmController.text,
      );
    } on AdminRemoteApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Gagal menghubungi server untuk mengubah kata sandi.';
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    _showMessage(
      errorMessage ??
          (changed
              ? 'Kata sandi berhasil diubah.'
              : 'Kata sandi saat ini salah.'),
    );
    if (changed) {
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      _formKey.currentState!.reset();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 52,
              color: colorScheme.surface,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Kembali',
                      icon: const Icon(
                        PhosphorIconsRegular.arrowLeft,
                        size: 19,
                      ),
                      color: colorScheme.primary,
                      onPressed: () => context.pop(),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _passwordField(
                        colorScheme: colorScheme,
                        key: const ValueKey('admin-current-password-field'),
                        label: 'Kata Sandi Saat Ini',
                        hint: 'Masukkan kata sandi saat ini',
                        controller: _currentController,
                        isVisible: _currentVisible,
                        onVisibilityChanged: (value) =>
                            setState(() => _currentVisible = value),
                        validator: (value) => (value ?? '').isEmpty
                            ? 'Kata sandi saat ini wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                        colorScheme: colorScheme,
                        key: const ValueKey('admin-new-password-field'),
                        label: 'Kata Sandi Baru',
                        hint: 'Masukkan kata sandi baru',
                        controller: _newController,
                        isVisible: _newVisible,
                        onVisibilityChanged: (value) =>
                            setState(() => _newVisible = value),
                        validator: (value) {
                          final password = value ?? '';
                          if (password.isEmpty) {
                            return 'Kata sandi baru wajib diisi.';
                          }
                          if (password.length < _minimumPasswordLength) {
                            return 'Kata sandi minimal $_minimumPasswordLength karakter.';
                          }
                          if (password == _currentController.text) {
                            return 'Kata sandi baru harus berbeda.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                        colorScheme: colorScheme,
                        key: const ValueKey('admin-confirm-password-field'),
                        label: 'Konfirmasi Kata Sandi Baru',
                        hint: 'Masukkan ulang kata sandi baru',
                        controller: _confirmController,
                        isVisible: _confirmVisible,
                        onVisibilityChanged: (value) =>
                            setState(() => _confirmVisible = value),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Konfirmasi kata sandi wajib diisi.';
                          }
                          if (value != _newController.text) {
                            return 'Konfirmasi kata sandi tidak sama.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            disabledBackgroundColor: colorScheme.primary
                                .withValues(alpha: 0.4),
                            disabledForegroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Text(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required Key key,
    required ColorScheme colorScheme,
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isVisible,
    required ValueChanged<bool> onVisibilityChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          key: key,
          controller: controller,
          obscureText: !isVisible,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary),
            ),
            suffixIcon: IconButton(
              onPressed: () => onVisibilityChanged(!isVisible),
              tooltip: isVisible
                  ? 'Sembunyikan password'
                  : 'Tampilkan password',
              icon: Icon(
                isVisible
                    ? PhosphorIconsRegular.eyeSlash
                    : PhosphorIconsRegular.eye,
                size: 19,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
