import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dosen/dummy_lecturer_auth_repository.dart';
import '../../data/dosen/lecturer_profile_preview.dart';
import '../../routing/lecturer_route_paths.dart';

const _minimumPasswordLength = 8;

class LecturerChangePasswordPage extends StatefulWidget {
  const LecturerChangePasswordPage({super.key, this.email});

  /// Akun yang kata sandinya diubah. Default ke akun dosen yang sedang login.
  final String? email;

  @override
  State<LecturerChangePasswordPage> createState() =>
      _LecturerChangePasswordPageState();
}

class _LecturerChangePasswordPageState
    extends State<LecturerChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSubmitting = false;

  String get _email => widget.email ?? lecturerProfilePreview.email;

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
      await lecturerAuthRepository.changePassword(
        email: _email,
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
      context.go(LecturerRoutePaths.profil);
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
            Container(
              color: colorScheme.surface,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.go(LecturerRoutePaths.profil),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LecturerPasswordField(
                        label: 'Kata Sandi Saat Ini',
                        hint: 'Masukkan kata sandi saat ini',
                        controller: _currentController,
                        enabled: !_isSubmitting,
                        validator: _validateCurrent,
                      ),
                      const SizedBox(height: 12),
                      _LecturerPasswordField(
                        label: 'Kata Sandi Baru',
                        hint: 'Masukkan kata sandi',
                        controller: _newController,
                        enabled: !_isSubmitting,
                        validator: _validateNew,
                      ),
                      const SizedBox(height: 12),
                      _LecturerPasswordField(
                        label: 'Konfirmasi Kata Sandi Baru',
                        hint: 'Masukkan ulang kata sandi',
                        controller: _confirmationController,
                        enabled: !_isSubmitting,
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
}

class _LecturerPasswordField extends StatefulWidget {
  const _LecturerPasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_LecturerPasswordField> createState() => _LecturerPasswordFieldState();
}

class _LecturerPasswordFieldState extends State<_LecturerPasswordField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colorScheme.outline),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: !_isVisible,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
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
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: _isVisible
                  ? 'Sembunyikan kata sandi'
                  : 'Tampilkan kata sandi',
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}
