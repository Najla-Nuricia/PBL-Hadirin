import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dosen/dummy_lecturer_auth_repository.dart';
import '../../../data/dosen/lecturer_account.dart';
import '../../../routing/lecturer_route_paths.dart';
import '../../../theme/style/auth_style.dart';
import '../../mhs/auth/widgets/auth_buttons.dart';
import '../../mhs/auth/widgets/auth_header.dart';
import '../../mhs/auth/widgets/auth_info_banner.dart';
import '../../mhs/auth/widgets/auth_scaffold.dart';
import '../../mhs/auth/widgets/auth_text_field.dart';

const _minimumPasswordLength = 8;

class LecturerRegisterPage extends StatefulWidget {
  const LecturerRegisterPage({super.key});

  @override
  State<LecturerRegisterPage> createState() => _LecturerRegisterPageState();
}

class _LecturerRegisterPageState extends State<LecturerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nipController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(LecturerRoutePaths.login);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final draft = LecturerRegistrationDraft(
      fullName: _nameController.text.trim(),
      staffId: _nipController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isSubmitting = true);
    try {
      final isEmailRegistered = await lecturerAuthRepository.isEmailRegistered(
        draft.email,
      );
      if (!mounted) return;

      if (isEmailRegistered) {
        setState(() => _isSubmitting = false);
        _showMessage('Email sudah terdaftar. Silakan login.');
        return;
      }

      await lecturerAuthRepository.register(draft);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage('Registrasi dosen berhasil. Silakan login.');
      context.go(LecturerRoutePaths.login);
    } on EmailAlreadyRegisteredException {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage('Email sudah terdaftar. Silakan login.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateRequired(String? value, String fieldName) {
    return (value ?? '').trim().isEmpty ? '$fieldName wajib diisi.' : null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Email wajib diisi.';
    if (!email.contains('@')) return 'Email tidak valid.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Kata sandi wajib diisi.';
    if (password.length < _minimumPasswordLength) {
      return 'Kata sandi minimal $_minimumPasswordLength karakter.';
    }
    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if ((value ?? '').isEmpty) return 'Konfirmasi kata sandi wajib diisi.';
    if (value != _passwordController.text) {
      return 'Konfirmasi kata sandi tidak sama.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: 'Registrasi Dosen',
            subtitle: 'Isi data diri kamu',
            activeSteps: 1,
            onBack: _goBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AuthStyle.contentHorizontalPadding,
                0,
                AuthStyle.contentHorizontalPadding,
                32,
              ),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthTextField(
                        label: 'Nama Dosen',
                        hintText: 'Nama lengkap dengan gelar',
                        controller: _nameController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        validator: (value) =>
                            _validateRequired(value, 'Nama dosen'),
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'NIP',
                        hintText: 'Nomor Induk Pegawai',
                        controller: _nipController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        autofillHints: const [AutofillHints.username],
                        validator: (value) => _validateRequired(value, 'NIP'),
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Email',
                        hintText: 'nama@univ.ac.id',
                        controller: _emailController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Kata Sandi',
                        hintText: 'Masukkan kata sandi',
                        controller: _passwordController,
                        enabled: !_isSubmitting,
                        isPassword: true,
                        showVisibilityToggle: true,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Konfirmasi Kata Sandi',
                        hintText: 'Ulangi kata sandi',
                        controller: _confirmationController,
                        enabled: !_isSubmitting,
                        isPassword: true,
                        showVisibilityToggle: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: _validatePasswordConfirmation,
                      ),
                      const SizedBox(height: 16),
                      const AuthInfoBanner(
                        message:
                            'Data yang kamu isi dipakai untuk login ke akun '
                            'dosen. Cek kembali sebelum mendaftar.',
                      ),
                      const SizedBox(height: 16),
                      AuthPrimaryButton(
                        label: 'Daftar',
                        onPressed: _submit,
                        isLoading: _isSubmitting,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
