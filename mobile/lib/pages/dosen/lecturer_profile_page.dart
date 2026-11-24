import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/dosen/dummy_lecturer_auth_repository.dart';
import '../../data/dosen/lecturer_profile_preview.dart';
import '../../data/dosen/lecturer_providers.dart';
import '../../models/dosen/lecturer_profile.dart';
import '../../routing/lecturer_route_paths.dart';
import '../../theme/style/lecturer_style.dart';
import '../../widgets/widgets.dart';
import 'widgets/content_constraint.dart';
import 'widgets/lecturer_app_bar.dart';
import 'widgets/logout_confirmation_dialog.dart';
import 'widgets/section_card.dart';

const _maxPhotoSizeInBytes = 5 * 1024 * 1024;

class LecturerProfilePage extends ConsumerStatefulWidget {
  const LecturerProfilePage({this.profile, super.key});

  /// Data lokal sebagai fallback saat backend belum merespons.
  final LecturerProfile? profile;

  @override
  ConsumerState<LecturerProfilePage> createState() =>
      _LecturerProfilePageState();
}

class _LecturerProfilePageState extends ConsumerState<LecturerProfilePage> {
  Uint8List? _photoBytes;
  bool _isUpdatingPhoto = false;
  LecturerProfile _profile = currentLecturerProfile();

  @override
  void initState() {
    super.initState();
    _photoBytes = widget.profile?.photoBytes;
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showLecturerLogoutDialog(
      context,
      fullName: _profile.fullName,
      email: _profile.email,
    );
    if (!shouldLogout || !mounted) return;
    lecturerAuthRepository.logout();
    ref.invalidate(dosenDashboardProvider);
    ref.read(attendanceQueryProvider.notifier).clear();
    context.go(LecturerRoutePaths.login);
  }

  Future<void> _pickPhoto() async {
    if (_isUpdatingPhoto) return;

    setState(() => _isUpdatingPhoto = true);
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) {
        if (mounted) setState(() => _isUpdatingPhoto = false);
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      if (bytes.length > _maxPhotoSizeInBytes) {
        setState(() => _isUpdatingPhoto = false);
        _showPhotoMessage('Ukuran foto maksimal 5 MB.');
        return;
      }

      setState(() {
        _photoBytes = bytes;
        _isUpdatingPhoto = false;
      });
      _showPhotoMessage('Foto profil diperbarui.');
    } on Exception {
      if (!mounted) return;
      setState(() => _isUpdatingPhoto = false);
      _showPhotoMessage('Gagal memuat foto. Coba lagi.');
    }
  }

  void _showPhotoMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dashboardAsync = ref.watch(dosenDashboardProvider);
    _profile =
        dashboardAsync.value?.dosen ??
        widget.profile ??
        currentLecturerProfile();

    return Scaffold(
      appBar: LecturerAppBar(
        title: 'Informasi Akun',
        onBack: () => context.go(LecturerRoutePaths.beranda),
        actions: [
          IconButton(
            tooltip: 'Muat ulang data akun',
            onPressed: () => ref.invalidate(dosenDashboardProvider),
            icon: dashboardAsync.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(PhosphorIconsRegular.arrowsClockwise),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: LecturerStyle.pageInsets,
          child: ContentConstraint(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (dashboardAsync.hasError) ...[
                  AppBanner(
                    tone: StatusTone.danger,
                    message:
                        'Gagal memuat data akun dari server. Menampilkan '
                        'data tersimpan.',
                    action: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: StatusTone.danger.ink,
                      ),
                      onPressed: () => ref.invalidate(dosenDashboardProvider),
                      child: const Text('Coba lagi'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                const SizedBox(height: AppSpacing.sm),
                _LecturerProfileHeader(
                  profile: _profile,
                  photoBytes: _photoBytes,
                  isUpdatingPhoto: _isUpdatingPhoto,
                  onPickPhoto: _pickPhoto,
                ),
                const SizedBox(height: AppSpacing.xl),
                _LecturerInformationCard(profile: _profile),
                const SizedBox(height: AppSpacing.lg),
                _LecturerActionsCard(
                  onPickPhoto: _pickPhoto,
                  onChangePassword: () =>
                      context.push(LecturerRoutePaths.changePassword),
                ),
                const SizedBox(height: AppSpacing.xxl),
                OutlinedButton.icon(
                  key: const ValueKey('lecturer-logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error),
                  ),
                  onPressed: _confirmLogout,
                  icon: const Icon(PhosphorIconsRegular.signOut, size: 20),
                  label: const Text('Keluar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LecturerProfileHeader extends StatelessWidget {
  const _LecturerProfileHeader({
    required this.profile,
    required this.photoBytes,
    required this.isUpdatingPhoto,
    required this.onPickPhoto,
  });

  final LecturerProfile profile;
  final Uint8List? photoBytes;
  final bool isUpdatingPhoto;
  final VoidCallback onPickPhoto;

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
            child: _LecturerAvatar(
              photoBytes: photoBytes,
              isUpdating: isUpdatingPhoto,
              onTap: onPickPhoto,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.fullName,
                  // Nama dosen dengan gelar bisa panjang.
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(
                    color: Colors.white,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  profile.role,
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

class _LecturerAvatar extends StatelessWidget {
  const _LecturerAvatar({
    required this.photoBytes,
    required this.isUpdating,
    required this.onTap,
  });

  static const _avatarSize = LecturerStyle.headerAvatarSize;
  static const _badgeSize = 24.0;

  final Uint8List? photoBytes;
  final bool isUpdating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final photo = photoBytes;

    return Semantics(
      button: true,
      label: 'Ubah foto profil',
      child: SizedBox(
        width: _avatarSize + AppSpacing.xs,
        height: _avatarSize + AppSpacing.xs,
        child: Stack(
          children: [
            Material(
              color: AppColors.brand100,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: isUpdating ? null : onTap,
                child: SizedBox(
                  width: _avatarSize,
                  height: _avatarSize,
                  child: photo == null
                      ? const Icon(
                          PhosphorIconsRegular.user,
                          size: 40,
                          color: AppColors.brand800,
                        )
                      : Image.memory(
                          photo,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                ),
              ),
            ),
            if (isUpdating)
              Positioned(
                left: 0,
                top: 0,
                width: _avatarSize,
                height: _avatarSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.scrim.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              // Lencana hanya penanda; ketukan diteruskan ke avatar.
              child: IgnorePointer(
                child: Container(
                  width: _badgeSize,
                  height: _badgeSize,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.camera,
                    size: 12,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LecturerInformationCard extends StatelessWidget {
  const _LecturerInformationCard({required this.profile});

  final LecturerProfile profile;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: LecturerStyle.detailCardInsets,
      child: Column(
        children: [
          _InformationRow(
            label: 'NIP/NIDN',
            value: profile.staffId,
            tabular: true,
          ),
          const Divider(),
          _InformationRow(label: 'Email', value: profile.email),
          const Divider(),
          _InformationRow(
            label: 'Nomor HP',
            value: profile.phoneNumber,
            tabular: true,
          ),
          const Divider(),
          _InformationRow(label: 'Peran', value: profile.role),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.label,
    required this.value,
    this.tabular = false,
  });

  final String label;
  final String value;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall;

    return AppKeyValueRow(
      label: label,
      trailing: Text(
        value.trim().isEmpty ? '-' : value,
        textAlign: TextAlign.right,
        style: tabular ? style?.tabular : style,
      ),
    );
  }
}

class _LecturerActionsCard extends StatelessWidget {
  const _LecturerActionsCard({
    required this.onPickPhoto,
    required this.onChangePassword,
  });

  final VoidCallback onPickPhoto;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _LecturerActionRow(
            key: const ValueKey('lecturer-change-photo'),
            icon: PhosphorIconsRegular.camera,
            label: 'Ubah Foto Profil',
            onTap: onPickPhoto,
          ),
          const Divider(),
          _LecturerActionRow(
            key: const ValueKey('lecturer-change-password'),
            icon: PhosphorIconsRegular.key,
            label: 'Ubah Kata Sandi',
            onTap: onChangePassword,
          ),
        ],
      ),
    );
  }
}

class _LecturerActionRow extends StatelessWidget {
  const _LecturerActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: LecturerStyle.rowMinHeight,
          ),
          child: Padding(
            padding: LecturerStyle.rowInsets,
            child: Row(
              children: [
                Container(
                  width: LecturerStyle.rowLeadingSize,
                  height: LecturerStyle.rowLeadingSize,
                  decoration: const BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: AppRadius.control,
                  ),
                  child: Icon(icon, size: 22, color: AppColors.brand700),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(PhosphorIconsRegular.caretRight, color: AppColors.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
