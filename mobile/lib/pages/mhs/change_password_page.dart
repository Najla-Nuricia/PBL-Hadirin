import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mhs/dummy_student_auth_repository.dart';
import '../../data/mhs/student_profile_preview.dart';
import '../../routing/student_route_paths.dart';

const _minimumPasswordLength = 8;

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, this.nim});

  /// Akun yang kata sandinya diubah. Default ke akun mahasiswa yang sedang login.
  final String? nim;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSubmitting = false;

  String get _nim => widget.nim ?? studentProfilePreview.studentId;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await studentAuthRepository.changePassword(
        nim: _nim,
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Kata sandi berhasil diperbarui.')),
        );
      context.go(StudentRoutePaths.beranda);
    } on WrongPasswordException {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Kata sandi saat ini salah.')),
        );
    }
  }

  String? _validateCurrent(String? value) {
    if ((value ?? '').isEmpty) return 'Kata sandi saat ini wajib diisi.';
    return null;
  }

  String? _validateNew(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Kata sandi baru wajib diisi.';
    if (password.length < _minimumPasswordLength) {
      return 'Kata sandi minimal $_minimumPasswordLength karakter.';
    }
    if (password == _currentController.text) {
      return 'Kata sandi baru harus berbeda.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if ((value ?? '').isEmpty) return 'Konfirmasi kata sandi wajib diisi.';
    if (value != _newController.text) {
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPasswordField(
                        colorScheme: colorScheme,
                        label: 'Kata Sandi Saat Ini',
                        hint: 'Masukkan kata sandi saat ini',
                        controller: _currentController,
                        validator: _validateCurrent,
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                        colorScheme: colorScheme,
                        label: 'Kata Sandi Baru',
                        hint: 'Masukkan kata sandi',
                        controller: _newController,
                        validator: _validateNew,
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                        colorScheme: colorScheme,
                        label: 'Konfirmasi Kata Sandi Baru',
                        hint: 'Masukkan ulang kata sandi',
                        controller: _confirmationController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: _validateConfirmation,
                      ),
                      const SizedBox(height: 24),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary,
                                    ),
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

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.go(StudentRoutePaths.beranda),
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
  required TextEditingController controller,
  required FormFieldValidator<String> validator,
  TextInputAction textInputAction = TextInputAction.next,
  ValueChanged<String>? onSubmitted,
}) {
  return _StudentPasswordField(
    colorScheme: colorScheme,
    label: label,
    hint: hint,
    controller: controller,
    validator: validator,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
  );
}

class _StudentPasswordField extends StatefulWidget {
  const _StudentPasswordField({
    required this.colorScheme,
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    required this.textInputAction,
    this.onSubmitted,
  });

  final ColorScheme colorScheme;
  final String label;
  final String hint;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_StudentPasswordField> createState() => _StudentPasswordFieldState();
}

class _StudentPasswordFieldState extends State<_StudentPasswordField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: widget.colorScheme.outline),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: widget.colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: widget.controller,
          obscureText: !_isVisible,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          style: TextStyle(color: widget.colorScheme.onSurface, fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: widget.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            errorStyle: const TextStyle(fontSize: 11),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 38,
              minHeight: 38,
            ),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _isVisible = !_isVisible),
              padding: EdgeInsets.zero,
              icon: Icon(
                _isVisible ? Icons.visibility_outlined : Icons.visibility_off,
                size: 15,
                color: widget.colorScheme.onSurfaceVariant,
              ),
              tooltip: _isVisible
                  ? 'Sembunyikan kata sandi'
                  : 'Tampilkan kata sandi',
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: widget.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}
