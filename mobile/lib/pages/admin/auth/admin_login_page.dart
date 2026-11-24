import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../routing/admin_route_paths.dart';
import '../../../widgets/widgets.dart';
import '../widgets/labeled_fields.dart';

abstract final class AdminDemoCredentials {
  static const username = 'admin';
  static const password = '123';
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_usernameController.text.trim() == AdminDemoCredentials.username &&
        _passwordController.text == AdminDemoCredentials.password) {
      context.go(AdminRoutePaths.dataAkademik);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Username atau password salah.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: skyStatusBar,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkyHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WordmarkPill(),
                    const SizedBox(height: AppSpacing.xl),
                    Semantics(
                      header: true,
                      child: Text(
                        'Login Sekretaris Jurusan',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: AppColors.gownNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Kelola data akademik dan jadwal perkuliahan.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.gownNavy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.contentMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.lg,
                      AppSpacing.page,
                      AppSpacing.xxl,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AdminFieldLabel(label: 'Username'),
                          TextFormField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan Username',
                              prefixIcon: Icon(PhosphorIconsRegular.user),
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Username wajib diisi.'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const AdminFieldLabel(label: 'Password'),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'Masukkan Password',
                              prefixIcon: const Icon(PhosphorIconsRegular.lock),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () =>
                                      _isPasswordVisible = !_isPasswordVisible,
                                ),
                                tooltip: _isPasswordVisible
                                    ? 'Sembunyikan password'
                                    : 'Tampilkan password',
                                icon: Icon(
                                  _isPasswordVisible
                                      ? PhosphorIconsRegular.eyeSlash
                                      : PhosphorIconsRegular.eye,
                                ),
                              ),
                            ),
                            validator: (value) => (value ?? '').isEmpty
                                ? 'Password wajib diisi.'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          AppGradientButton(
                            onPressed: _submit,
                            label: 'Masuk',
                            icon: PhosphorIconsRegular.signIn,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}