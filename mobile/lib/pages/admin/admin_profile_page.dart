import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/admin_account.dart';
import '../../data/admin/admin_auth_repository.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';

/// Halaman Akun Admin dengan tata letak yang sama seperti profil
/// mahasiswa/dosen: AppBar langit, kartu hero gradien, bagian "Informasi Akun",
/// kartu aksi, dan tombol keluar di bawah. Tidak ada fitur ganti foto profil.
class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  bool _isRefreshing = false;
  bool _refreshFailed = false;

  AdminAccount? get _account => adminAuthRepository.currentAccount;

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await adminAuthRepository.loadProfile();
      if (!mounted) return;
      setState(() => _refreshFailed = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _refreshFailed = true);
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
    final text = Theme.of(context).textTheme;
    final account =
        _account ??
        const AdminAccount(
          username: 'admin',
          name: 'Administrator',
          role: 'Admin',
        );

    return Scaffold(
      appBar: SkyAppBar(
        title: const Text('Profil'),
        titleSpacing: AppSpacing.page,
        actions: [
          IconButton(
            tooltip: 'Muat ulang data akun',
            onPressed: _isRefreshing ? null : _refresh,
            icon: _isRefreshing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(PhosphorIconsRegular.arrowsClockwise),
          ),
        ],
      ),
      body: AuroraBackground(
        child: SafeArea(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_refreshFailed) ...[
                      AppBanner(
                        tone: StatusTone.warning,
                        message:
                            'Profil terbaru belum bisa dimuat. Menampilkan '
                            'data tersimpan.',
                        action: TextButton(
                          onPressed: _refresh,
                          style: TextButton.styleFrom(
                            foregroundColor: StatusTone.warning.ink,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          child: const Text('Coba lagi'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _AdminProfileHeader(account: account),
                    const SizedBox(height: AppSpacing.lg),
                    const AppSectionHeader(title: 'Informasi Akun'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          children: [
                            _AdminInfoRow(
                              label: 'Username',
                              value: account.username,
                              tabular: true,
                            ),
                            const Divider(),
                            _AdminInfoRow(
                              label: 'Email',
                              value: account.email.isEmpty
                                  ? 'Belum diisi'
                                  : account.email,
                              muted: account.email.isEmpty,
                            ),
                            const Divider(),
                            _AdminInfoRow(
                              label: 'Role',
                              value: account.role,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            key: const ValueKey('admin-change-password'),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: AppColors.brand50,
                                borderRadius: AppRadius.control,
                              ),
                              child: const Icon(
                                PhosphorIconsRegular.key,
                                size: 19,
                                color: AppColors.brand700,
                              ),
                            ),
                            title: Text(
                              'Ubah Kata Sandi',
                              style: text.titleSmall,
                            ),
                            trailing: const Icon(
                              PhosphorIconsRegular.caretRight,
                              color: AppColors.inkFaint,
                            ),
                            onTap: () =>
                                context.push(AdminRoutePaths.changePassword),
                          ),
                          const Divider(),
                          ListTile(
                            key: const ValueKey('admin-change-email'),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: AppColors.brand50,
                                borderRadius: AppRadius.control,
                              ),
                              child: const Icon(
                                PhosphorIconsRegular.envelope,
                                size: 19,
                                color: AppColors.brand700,
                              ),
                            ),
                            title: Text(
                              'Ubah Email',
                              style: text.titleSmall,
                            ),
                            trailing: const Icon(
                              PhosphorIconsRegular.caretRight,
                              color: AppColors.inkFaint,
                            ),
                            onTap: _changeEmail,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      key: const ValueKey('admin-logout'),
                      onPressed: _confirmLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        backgroundColor: Colors.white.withValues(alpha: 0.6),
                        side: BorderSide(
                          color: colorScheme.error.withValues(alpha: 0.45),
                        ),
                      ),
                      icon: const Icon(PhosphorIconsRegular.signOut, size: 20),
                      label: const Text('Keluar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu hero profil admin, memakai gradien dan inisial seperti profil
/// mahasiswa/dosen. Admin tidak memiliki foto profil, jadi tidak ada tombol
/// kamera maupun aksi mengganti foto.
class _AdminProfileHeader extends StatelessWidget {
  const _AdminProfileHeader({required this.account});

  final AdminAccount account;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadius.hero,
        boxShadow: AppColors.shadowLifted,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
            child: _AdminAvatar(name: account.name),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  account.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.onBrandMuted,
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

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.name});

  static const double _size = 64;

  final String name;

  String get _initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word.characters.first.toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final initials = _initials;

    return ClipOval(
      child: SizedBox.square(
        dimension: _size,
        child: ColoredBox(
          color: AppColors.brand100,
          child: Center(
            child: initials.isEmpty
                ? const Icon(
                    PhosphorIconsRegular.userCircle,
                    size: 28,
                    color: AppColors.brand800,
                  )
                : Text(
                    initials,
                    textScaler: TextScaler.noScaling,
                    style: text.titleLarge?.copyWith(
                      color: AppColors.brand800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Satu baris "Informasi Akun": label di kiri, nilai di kanan (seperti halaman
/// profil mahasiswa dan dosen). Nilai kosong tampil lebih redup.
class _AdminInfoRow extends StatelessWidget {
  const _AdminInfoRow({
    required this.label,
    required this.value,
    this.muted = false,
    this.tabular = false,
  });

  final String label;
  final String value;
  final bool muted;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final style = muted
        ? text.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)
        : tabular
        ? text.titleSmall?.tabular
        : text.titleSmall;

    return AppKeyValueRow(
      label: label,
      trailing: Text(value, textAlign: TextAlign.right, style: style),
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
                        ? PhosphorIconsRegular.eyeSlash
                        : PhosphorIconsRegular.eye,
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
      icon: Icon(PhosphorIconsRegular.signOut, color: colorScheme.error),
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
