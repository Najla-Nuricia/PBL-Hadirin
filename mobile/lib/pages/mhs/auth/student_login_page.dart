import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mhs/dummy_student_auth_repository.dart';
import '../../../routing/student_route_paths.dart';
import '../../../theme/style/auth_style.dart';
import '../../../widgets/widgets.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      final account = await studentAuthRepository.login(
        nim: _nimController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (account == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('NIM atau password salah.')),
          );
        return;
      }

      context.go(StudentRoutePaths.beranda);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final msg = e is RemoteApiException
          ? e.message
          : 'Gagal masuk. Periksa koneksi server.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _showForgotPasswordUnavailable() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Fitur lupa kata sandi belum tersedia.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'Login Mahasiswa',
              subtitle: 'Masuk dengan NIM dan kata sandi.',
              activeSteps: 1,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AuthStyle.contentHorizontalPadding,
              ),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthTextField(
                        label: 'NIM',
                        hintText: 'Masukkan NIM',
                        controller: _nimController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        autofillHints: const [AutofillHints.username],
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'NIM wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: AuthStyle.fieldGap),
                      AuthTextField(
                        label: 'Password',
                        hintText: 'Masukkan password',
                        controller: _passwordController,
                        enabled: !_isSubmitting,
                        isPassword: true,
                        showVisibilityToggle: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) => (value ?? '').isEmpty
                            ? 'Password wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordUnavailable,
                          child: const Text('Lupa kata sandi?'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AuthPrimaryButton(
                        label: 'Masuk',
                        onPressed: _submit,
                        isLoading: _isSubmitting,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AuthSecondaryButton(
                        label: 'Daftar',
                        onPressed: _isSubmitting
                            ? null
                            : () => context.push(StudentRoutePaths.register),
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
