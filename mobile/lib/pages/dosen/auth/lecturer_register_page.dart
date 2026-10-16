import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/lecturer_route_paths.dart';
import '../../mhs/auth/widgets/auth_buttons.dart';
import '../../mhs/auth/widgets/auth_header.dart';
import '../../mhs/auth/widgets/auth_scaffold.dart';
import '../../mhs/auth/widgets/auth_text_field.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrasi dosen berhasil. Silakan login.')),
    );
    context.go(LecturerRoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(title: 'Registrasi Dosen', activeSteps: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthTextField(
                      label: 'Nama Dosen',
                      hintText: 'Nama',
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      validator: _required('Nama dosen'),
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      label: 'NIP',
                      hintText: 'Masukkan NIP',
                      controller: _nipController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: _required('NIP'),
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      label: 'Email',
                      hintText: 'nama@gmail.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (email.isEmpty) return 'Email wajib diisi.';
                        if (!email.contains('@')) return 'Email tidak valid.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      label: 'Kata Sandi',
                      hintText: 'Masukkan kata sandi',
                      controller: _passwordController,
                      isPassword: true,
                      showVisibilityToggle: true,
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Kata sandi wajib diisi.';
                        }
                        if (value!.length < 6) {
                          return 'Kata sandi minimal 6 karakter.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      label: 'Konfirmasi Kata Sandi',
                      hintText: 'Ulangi kata sandi',
                      controller: _confirmationController,
                      isPassword: true,
                      showVisibilityToggle: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) => value != _passwordController.text
                          ? 'Konfirmasi kata sandi tidak cocok.'
                          : null,
                    ),
                    const SizedBox(height: 28),
                    AuthPrimaryButton(label: 'Daftar', onPressed: _submit),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  FormFieldValidator<String> _required(String field) {
    return (value) =>
        (value ?? '').trim().isEmpty ? '$field wajib diisi.' : null;
  }
}
