import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mhs/dummy_student_auth_repository.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({required this.nim, this.repository, super.key});

  final String nim;
  final DummyStudentAuthRepository? repository;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  static const _minimumPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmationVisible = false;
  bool _isCurrentPasswordVisible = false;
  bool _isSubmitting = false;

  DummyStudentAuthRepository get _repository =>
      widget.repository ?? studentAuthRepository;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    bool changed = false;
    String? errorMessage;
    try {
      changed = await _repository.changePassword(
        nim: widget.nim,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
    } on RemoteApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Gagal menghubungi server untuk mengubah kata sandi.';
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final message = errorMessage ??
        (changed
            ? 'Kata sandi berhasil diubah.'
            : 'Kata sandi saat ini salah.');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    if (changed) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmationController.clear();
      _formKey.currentState!.reset();
    }
  }

  String? _validateCurrentPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Kata sandi saat ini wajib diisi.';
    return null;
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Kata sandi baru wajib diisi.';
    if (password.length < _minimumPasswordLength) {
      return 'Kata sandi minimal $_minimumPasswordLength karakter.';
    }
    if (password == _currentPasswordController.text) {
      return 'Kata sandi baru harus berbeda.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi.';
    }
    if (value != _newPasswordController.text) {
      return 'Konfirmasi kata sandi tidak sama.';
    }
    return null;
  }

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
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPasswordField(
                            key: const ValueKey('current-password-field'),
                            colorScheme: colorScheme,
                            label: 'Kata Sandi Saat Ini',
                            hint: 'Masukkan kata sandi saat ini',
                            controller: _currentPasswordController,
                            isVisible: _isCurrentPasswordVisible,
                            enabled: !_isSubmitting,
                            validator: _validateCurrentPassword,
                            onVisibilityChanged: (value) {
                              setState(() => _isCurrentPasswordVisible = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordField(
                            key: const ValueKey('new-password-field'),
                            colorScheme: colorScheme,
                            label: 'Kata Sandi Baru',
                            hint: 'Masukkan kata sandi baru',
                            controller: _newPasswordController,
                            isVisible: _isNewPasswordVisible,
                            enabled: !_isSubmitting,
                            validator: _validateNewPassword,
                            onVisibilityChanged: (value) {
                              setState(() => _isNewPasswordVisible = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordField(
                            key: const ValueKey('confirm-password-field'),
                            colorScheme: colorScheme,
                            label: 'Konfirmasi Kata Sandi Baru',
                            hint: 'Masukkan ulang kata sandi baru',
                            controller: _confirmationController,
                            isVisible: _isConfirmationVisible,
                            enabled: !_isSubmitting,
                            validator: _validateConfirmation,
                            onVisibilityChanged: (value) {
                              setState(() => _isConfirmationVisible = value);
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
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
  required Key key,
  required ColorScheme colorScheme,
  required String label,
  required String hint,
  required TextEditingController controller,
  required bool isVisible,
  required bool enabled,
  required String? Function(String?) validator,
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
      TextFormField(
        key: key,
        controller: controller,
        enabled: enabled,
        obscureText: !isVisible,
        style: TextStyle(color: colorScheme.onSurface, fontSize: 11),
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
            onPressed: enabled ? () => onVisibilityChanged(!isVisible) : null,
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
    ],
  );
}
