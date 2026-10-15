import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/lecturer_route_paths.dart';
import '../../mhs/auth/widgets/auth_buttons.dart';
import '../../mhs/auth/widgets/auth_header.dart';
import '../../mhs/auth/widgets/auth_scaffold.dart';
import '../../mhs/auth/widgets/auth_text_field.dart';

abstract final class LecturerDemoCredentials {
  static const email = 'dosen@hadirin.id';
  static const password = 'dosen123';
}

class LecturerLoginPage extends StatefulWidget {
  const LecturerLoginPage({super.key});

  @override
  State<LecturerLoginPage> createState() => _LecturerLoginPageState();
}

class _LecturerLoginPageState extends State<LecturerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_emailController.text.trim().toLowerCase() !=
            LecturerDemoCredentials.email ||
        _passwordController.text != LecturerDemoCredentials.password) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Email atau password salah.')),
        );
      return;
    }

    context.go(LecturerRoutePaths.beranda);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(title: 'Login Dosen', activeSteps: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthTextField(
                      label: 'Email Address',
                      hintText: 'name@email.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Email wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      label: 'Password',
                      hintText: 'Create a password',
                      controller: _passwordController,
                      isPassword: true,
                      showVisibilityToggle: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) => (value ?? '').isEmpty
                          ? 'Password wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 28),
                    AuthPrimaryButton(label: 'Masuk', onPressed: _submit),
                    const SizedBox(height: 8),
                    AuthSecondaryButton(
                      label: 'Daftar',
                      onPressed: () =>
                          context.push(LecturerRoutePaths.register),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
