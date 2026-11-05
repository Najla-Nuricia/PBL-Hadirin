import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dosen/dummy_lecturer_auth_repository.dart';
import '../../../routing/lecturer_route_paths.dart';
import '../../../theme/style/auth_style.dart';
import '../../mhs/auth/widgets/auth_buttons.dart';
import '../../mhs/auth/widgets/auth_header.dart';
import '../../mhs/auth/widgets/auth_scaffold.dart';
import '../../mhs/auth/widgets/auth_text_field.dart';

class LecturerLoginPage extends StatefulWidget {
  const LecturerLoginPage({super.key});

  @override
  State<LecturerLoginPage> createState() => _LecturerLoginPageState();
}

class _LecturerLoginPageState extends State<LecturerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    final account = await lecturerAuthRepository.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (account == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Email atau password salah.')),
        );
      return;
    }

    context.go(LecturerRoutePaths.beranda);
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
          const AuthHeader(title: 'Login Dosen', activeSteps: 1),
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
                        label: 'Email',
                        hintText: 'nama@univ.ac.id',
                        controller: _emailController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (email.isEmpty) return 'Email wajib diisi.';
                          if (!email.contains('@')) return 'Email tidak valid.';
                          return null;
                        },
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
                          onPressed: _isSubmitting
                              ? null
                              : _showForgotPasswordUnavailable,
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontSize: AuthStyle.captionSize,
                            ),
                          ),
                          child: const Text('Lupa password?'),
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
                            : () => context.push(LecturerRoutePaths.register),
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
