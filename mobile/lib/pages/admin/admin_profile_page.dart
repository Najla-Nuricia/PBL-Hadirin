import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/admin_account.dart';
import '../../data/admin/admin_auth_repository.dart';
import '../../routing/admin_route_paths.dart';

/// Halaman Akun Admin — mengikuti pola halaman profil mahasiswa/dosen.
/// Tidak ada fitur ganti foto profil.
class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  bool _isRefreshing = false;

  AdminAccount? get _account => adminAuthRepository.currentAccount;

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await adminAuthRepository.loadProfile();
    } catch (e) {
      if (mounted) _showMessage('$e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _changeEmail() async {
    final result = await showDialog<({String email, String currentPassword})>(
      context: context,
      builder: (_) => _AdminEmailDialog(currentEmail: _account?.email ?? ''),
    );
    if (!mounted || result == null) return;

    try {
      await adminAuthRepository.updateEmail(
        result.email,
        currentPassword: result.currentPassword,
      );
      if (!mounted) return;
      _showMessage('Email berhasil diperbarui.');
    } on AdminRemoteApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Gagal menghubungi server untuk mengubah email.');
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _AdminLogoutDialog(),
    );
    if (confirmed != true || !mounted) return;
    adminAuthRepository.logout();
    context.go(AdminRoutePaths.login);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final account =
        _account ??
        const AdminAccount(
          username: 'admin',
          name: 'Administrator',
          role: 'Admin',
        );

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: colorScheme.surface,
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Informasi Akun',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Muat ulang data akun',
                            onPressed: _isRefreshing ? null : _refresh,
                            icon: _isRefreshing
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh,
                                    color: colorScheme.primary,
                                    size: 19,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 42,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      account.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      account.role.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _AdminInfoRow(
                            icon: Icons.alternate_email,
                            label: 'Username',
                            value: account.username,
                          ),
                          _AdminDivider(colorScheme: colorScheme),
                          _AdminInfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: account.email.isEmpty
                                ? 'Belum diisi'
                                : account.email,
                          ),
                          _AdminDivider(colorScheme: colorScheme),
                          _AdminInfoRow(
                            icon: Icons.person_outline,
                            label: 'Role',
                            value: account.role,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _AdminActionRow(
                            icon: Icons.mail_outline,
                            iconColor: colorScheme.primary,
                            iconBg: colorScheme.primaryContainer,
                            label: 'Ubah Email',
                            onTap: _changeEmail,
                            valueKey: const ValueKey('admin-change-email'),
                          ),
                          _AdminDivider(colorScheme: colorScheme),
                          _AdminActionRow(
                            icon: Icons.key_outlined,
                            iconColor: const Color(0xFFF5A623),
                            iconBg: const Color(0xFFFEF3C7),
                            label: 'Ubah Kata Sandi',
                            onTap: () =>
                                context.push(AdminRoutePaths.changePassword),
                            valueKey: const ValueKey('admin-change-password'),
                          ),
                          _AdminDivider(colorScheme: colorScheme),
                          _AdminActionRow(
                            icon: Icons.logout,
                            iconColor: colorScheme.error,
                            iconBg: colorScheme.errorContainer,
                            label: 'Keluar',
                            labelColor: colorScheme.error,
                            onTap: _confirmLogout,
                            showChevron: false,
                            isLast: true,
                            valueKey: const ValueKey('admin-logout'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminInfoRow extends StatelessWidget {
  const _AdminInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, isLast ? 14 : 8),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionRow extends StatelessWidget {
  const _AdminActionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.showChevron = true,
    this.isLast = false,
    this.valueKey,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final bool showChevron;
  final bool isLast;
  final ValueKey<String>? valueKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      key: valueKey,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 10, 14, isLast ? 10 : 6),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _AdminDivider extends StatelessWidget {
  const _AdminDivider({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: colorScheme.outlineVariant,
      indent: 14,
      endIndent: 14,
    );
  }
}

class _AdminEmailDialog extends StatefulWidget {
  const _AdminEmailDialog({required this.currentEmail});

  final String currentEmail;

  @override
  State<_AdminEmailDialog> createState() => _AdminEmailDialogState();
}

class _AdminEmailDialogState extends State<_AdminEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _controller.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Email'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('admin-email-field'),
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email baru'),
              validator: (value) {
                final email = (value ?? '').trim();
                if (email.isEmpty) return 'Email wajib diisi.';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'Format email tidak valid.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin-email-password-field'),
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Kata sandi saat ini',
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                  tooltip: _isPasswordVisible
                      ? 'Sembunyikan kata sandi'
                      : 'Tampilkan kata sandi',
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                  ),
                ),
              ),
              validator: (value) => (value ?? '').isEmpty
                  ? 'Kata sandi saat ini wajib diisi.'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop((
              email: _controller.text.trim(),
              currentPassword: _passwordController.text,
            ));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _AdminLogoutDialog extends StatelessWidget {
  const _AdminLogoutDialog();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.logout_rounded, color: colorScheme.error),
      title: const Text('Keluar dari akun?'),
      content: const Text(
        'Sesi admin akan berakhir dan Anda perlu masuk lagi.',
      ),
      actions: [
        TextButton(
          key: const ValueKey('admin-logout-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const ValueKey('admin-logout-confirm'),
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Keluar'),
        ),
      ],
    );
  }
}
