import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mhs/dummy_student_auth_repository.dart';
import '../../../data/mhs/student_account.dart';
import '../../../routing/student_route_paths.dart';
import '../../../theme/style/auth_style.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_info_banner.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

const _minimumPasswordLength = 8;

class StudentRegisterPage extends StatefulWidget {
  const StudentRegisterPage({super.key});

  @override
  State<StudentRegisterPage> createState() => _StudentRegisterPageState();
}

class _StudentRegisterPageState extends State<StudentRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nimController = TextEditingController();
  final _classNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _nimController.dispose();
    _classNameController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(StudentRoutePaths.login);
    }
  }

  Future<void> _continueToFaceScan() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final draft = StudentRegistrationDraft(
      fullName: _fullNameController.text.trim(),
      nim: _nimController.text.trim(),
      className: _classNameController.text.trim().toUpperCase(),
      password: _passwordController.text,
    );

    setState(() => _isSubmitting = true);
    final isNimRegistered = await studentAuthRepository.isNimRegistered(
      draft.nim,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (isNimRegistered) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('NIM sudah terdaftar. Silakan login.')),
        );
      return;
    }

    context.push(StudentRoutePaths.registerFaceScan, extra: draft);
  }

  String? _validateRequired(String? value, String fieldName) {
    return (value ?? '').trim().isEmpty ? '$fieldName wajib diisi.' : null;
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
            title: 'Registrasi Mahasiswa',
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
                        label: 'Nama Lengkap',
                        hintText: 'Nama lengkap kamu',
                        controller: _fullNameController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        validator: (value) =>
                            _validateRequired(value, 'Nama lengkap'),
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'NIM',
                        hintText: 'Nomor Induk Mahasiswa',
                        controller: _nimController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        autofillHints: const [AutofillHints.username],
                        validator: (value) => _validateRequired(value, 'NIM'),
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Kelas',
                        hintText: 'Contoh: 3F-TI',
                        controller: _classNameController,
                        enabled: !_isSubmitting,
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) => _validateRequired(value, 'Kelas'),
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
                        controller: _passwordConfirmationController,
                        enabled: !_isSubmitting,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _continueToFaceScan(),
                        validator: _validatePasswordConfirmation,
                      ),
                      const SizedBox(height: 16),
                      const AuthInfoBanner(
                        message:
                            'Setelah ini kamu akan diminta scan wajah dari 5 '
                            'arah untuk keperluan absensi.',
                      ),
                      const SizedBox(height: 16),
                      AuthPrimaryButton(
                        label: 'Lanjut ke Scan Wajah →',
                        onPressed: _continueToFaceScan,
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
