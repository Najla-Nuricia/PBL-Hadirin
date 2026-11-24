import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../data/admin/admin_auth_repository.dart';
import '../../../routing/admin_route_paths.dart';
import '../../../widgets/widgets.dart';

/// Kompatibilitas dengan kode/QA lama yang memakai kredensial demo.
abstract final class AdminDemoCredentials {
  static String get username => AdminAuthRepository.demoUsername;
  static String get password => AdminAuthRepository.demoPassword;
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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final account = await adminAuthRepository.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (account != null) {
        context.go(AdminRoutePaths.dataAkademik);
        return;
      }
      _showError('Username atau password admin salah.');
    } on AdminRemoteApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Login admin gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

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
                        style: text.headlineLarge?.copyWith(
                          color: AppColors.gownNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Kelola data akademik dan jadwal perkuliahan.',
                      style: text.bodyLarge?.copyWith(
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
                          Text('Username', style: text.labelLarge),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            decoration:
                                _inputDecoration(
                                  context,
                                  hintText: 'Masukkan Username',
                                ).copyWith(
                                  prefixIcon: const Icon(
                                    PhosphorIconsRegular.user,
                                  ),
                                ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Username wajib diisi.'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Password', style: text.labelLarge),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            onFieldSubmitted: (_) => _submit(),
                            decoration:
                                _inputDecoration(
                                  context,
                                  hintText: 'Masukkan Password',
                                ).copyWith(
                                  prefixIcon: const Icon(
                                    PhosphorIconsRegular.lock,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _isPasswordVisible =
                                          !_isPasswordVisible,
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
                            onPressed: _isSubmitting ? null : _submit,
                            label: 'Masuk',
                            icon: PhosphorIconsRegular.signIn,
                            isBusy: _isSubmitting,
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

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    );
  }
}
