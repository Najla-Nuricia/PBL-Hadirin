import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/dosen/dummy_lecturer_auth_repository.dart';
import '../../data/dosen/lecturer_profile_preview.dart';
import '../../data/dosen/lecturer_providers.dart';
import '../../routing/lecturer_route_paths.dart';
import '../../theme/style/auth_style.dart';
import '../../theme/style/lecturer_style.dart';
import '../../widgets/widgets.dart';
import '../mhs/auth/widgets/auth_text_field.dart';
import 'widgets/content_constraint.dart';
import 'widgets/lecturer_app_bar.dart';
import 'widgets/lecturer_bottom_bar.dart';

const _minimumPasswordLength = 8;

class LecturerChangePasswordPage extends ConsumerStatefulWidget {
  const LecturerChangePasswordPage({super.key, this.email});

  /// Akun yang kata sandinya diubah. Default ke akun dosen yang sedang login.
  final String? email;

  @override
  ConsumerState<LecturerChangePasswordPage> createState() =>
      _LecturerChangePasswordPageState();
}

class _LecturerChangePasswordPageState
    extends ConsumerState<LecturerChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  // Pesan galat tampil lewat messenger milik layar ini supaya muncul di atas
  // tombol Simpan, bukan menutupinya. Pesan berhasil memakai messenger
  // aplikasi karena harus tetap terlihat setelah kembali ke profil.
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSubmitting = false;

  String get _email =>
      widget.email ??
      ref.read(dosenDashboardProvider).value?.dosen.email ??
      currentLecturerProfile().email;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await lecturerAuthRepository.changePassword(
        email: _email,
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Kata sandi berhasil diperbarui.')),
        );
      context.go(LecturerRoutePaths.profil);
    } on WrongPasswordException {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Kata sandi saat ini salah.')),
        );
    }
  }

  String? _validateCurrent(String? value) {
    if ((value ?? '').isEmpty) return 'Kata sandi saat ini wajib diisi.';
    return null;
  }

  String? _validateNew(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Kata sandi baru wajib diisi.';
    if (password.length < _minimumPasswordLength) {
      return 'Kata sandi minimal $_minimumPasswordLength karakter.';
    }
    if (password == _currentController.text) {
      return 'Kata sandi baru harus berbeda.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if ((value ?? '').isEmpty) return 'Konfirmasi kata sandi wajib diisi.';
    if (value != _newController.text) {
      return 'Konfirmasi kata sandi tidak sama.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(key: _messengerKey, child: _buildPage());
  }

  Widget _buildPage() {
    return Scaffold(
      appBar: LecturerAppBar(
        title: 'Ubah Kata Sandi',
        onBack: () => context.go(LecturerRoutePaths.profil),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: LecturerStyle.pageInsets,
          child: ContentConstraint(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  AuthTextField(
                    label: 'Kata Sandi Saat Ini',
                    hintText: 'Masukkan kata sandi saat ini',
                    controller: _currentController,
                    enabled: !_isSubmitting,
                    isPassword: true,
                    showVisibilityToggle: true,
                    validator: _validateCurrent,
                  ),
                  const SizedBox(height: AuthStyle.fieldGap),
                  AuthTextField(
                    label: 'Kata Sandi Baru',
                    hintText: 'Masukkan kata sandi',
                    helperText: 'Minimal $_minimumPasswordLength karakter.',
                    controller: _newController,
                    enabled: !_isSubmitting,
                    isPassword: true,
                    showVisibilityToggle: true,
                    validator: _validateNew,
                  ),
                  const SizedBox(height: AuthStyle.fieldGap),
                  AuthTextField(
                    label: 'Konfirmasi Kata Sandi Baru',
                    hintText: 'Masukkan ulang kata sandi',
                    controller: _confirmationController,
                    enabled: !_isSubmitting,
                    isPassword: true,
                    showVisibilityToggle: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: _validateConfirmation,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: LecturerBottomBar(
        child: FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting ? const _SavingLabel() : const Text('Simpan'),
        ),
      ),
    );
  }
}

class _SavingLabel extends StatelessWidget {
  const _SavingLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            // Mengikuti warna teks tombol yang sedang nonaktif.
            color: DefaultTextStyle.of(context).style.color,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Text('Menyimpan…'),
      ],
    );
  }
}
