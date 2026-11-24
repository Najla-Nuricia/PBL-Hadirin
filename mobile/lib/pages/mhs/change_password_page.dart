import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:go_router/go_router.dart';

import '../../data/mhs/dummy_student_auth_repository.dart';
import '../../routing/student_route_paths.dart';
import '../../theme/style/auth_style.dart';
import '../../widgets/widgets.dart';
import 'auth/widgets/auth_buttons.dart';
import 'auth/widgets/auth_text_field.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({required this.nim, this.repository, super.key});

  final String nim;
  final DummyStudentAuthRepository? repository;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  static const _minimumPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSubmitting = false;

  DummyStudentAuthRepository get _repository =>
      widget.repository ?? studentAuthRepository;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    bool changed = false;
    String? errorMessage;
    try {
      changed = await _repository.changePassword(
        nim: widget.nim,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
    } on RemoteApiException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Gagal menghubungi server untuk mengubah kata sandi.';
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final message =
        errorMessage ??
        (changed
            ? 'Kata sandi berhasil diubah.'
            : 'Kata sandi saat ini salah.');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    if (changed) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmationController.clear();
      _formKey.currentState!.reset();
    }
  }

  String? _validateCurrentPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Kata sandi saat ini wajib diisi.';
    return null;
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Kata sandi baru wajib diisi.';
    if (password.length < _minimumPasswordLength) {
      return 'Kata sandi minimal $_minimumPasswordLength karakter.';
    }
    if (password == _currentPasswordController.text) {
      return 'Kata sandi baru harus berbeda.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi.';
    }
    if (value != _newPasswordController.text) {
      return 'Konfirmasi kata sandi tidak sama.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkyAppBar(
        leading: IconButton(
          onPressed: () => context.go(StudentRoutePaths.beranda),
          tooltip: 'Kembali',
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
        ),
        title: const Text('Ubah Kata Sandi'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthTextField(
                        fieldKey: const ValueKey('current-password-field'),
                        label: 'Kata Sandi Saat Ini',
                        hintText: 'Masukkan kata sandi saat ini',
                        controller: _currentPasswordController,
                        enabled: !_isSubmitting,
                        isPassword: true,
                        showVisibilityToggle: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: _validateCurrentPassword,
                      ),
                      const SizedBox(height: AuthStyle.fieldGap),
                      AuthTextField(
                        fieldKey: const ValueKey('new-password-field'),
                        label: 'Kata Sandi Baru',
                        hintText: 'Masukkan kata sandi baru',
                        helperText:
                            'Minimal $_minimumPasswordLength karakter dan '
                            'berbeda dari kata sandi saat ini.',
                        controller: _newPasswordController,
                        enabled: !_isSubmitting,
                        isPassword: true,
                        showVisibilityToggle: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: _validateNewPassword,
                      ),
                      const SizedBox(height: AuthStyle.fieldGap),
                      AuthTextField(
                        fieldKey: const ValueKey('confirm-password-field'),
                        label: 'Konfirmasi Kata Sandi Baru',
                        hintText: 'Masukkan ulang kata sandi baru',
                        controller: _confirmationController,
                        enabled: !_isSubmitting,
                        isPassword: true,
                        showVisibilityToggle: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: _validateConfirmation,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AuthPrimaryButton(
                        label: 'Simpan',
                        onPressed: _submit,
                        isLoading: _isSubmitting,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
