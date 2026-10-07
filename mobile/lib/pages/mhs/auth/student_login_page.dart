import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mhs/dummy_student_auth_repository.dart';
import '../../../routing/student_router.dart';
import '../../../theme/style/auth_style.dart';
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
  }

  void _showForgotPasswordUnavailable() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Fitur lupa password belum tersedia.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(title: 'Login Mahasiswa', activeSteps: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AuthStyle.contentHorizontalPadding,
                0,
                AuthStyle.contentHorizontalPadding,
                24,
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
                      const SizedBox(height: 20),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _showForgotPasswordUnavailable,
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontSize: AuthStyle.captionSize,
                            ),
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AuthPrimaryButton(
                        label: 'Masuk',
                        onPressed: _submit,
                        isLoading: _isSubmitting,
                      ),
                      const SizedBox(height: 9),
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
          ),
        ],
      ),
    );
  }
}
