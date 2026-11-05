import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/dosen/lecturer_profile.dart';
import '../../routing/lecturer_route_paths.dart';
import 'widgets/logout_confirmation_dialog.dart';

const _maxPhotoSizeInBytes = 5 * 1024 * 1024;

class LecturerProfilePage extends StatefulWidget {
  const LecturerProfilePage({
    required this.profile,
    super.key,
  });

  final LecturerProfile profile;

  @override
  State<LecturerProfilePage> createState() => _LecturerProfilePageState();
}

class _LecturerProfilePageState extends State<LecturerProfilePage> {
  Uint8List? _photoBytes;
  bool _isUpdatingPhoto = false;

  @override
  void initState() {
    super.initState();
    _photoBytes = widget.profile.photoBytes;
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showLecturerLogoutDialog(
      context,
      fullName: widget.profile.fullName,
      email: widget.profile.email,
    );
    if (!shouldLogout || !mounted) return;
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _LecturerProfileHeader(
              profile: widget.profile,
              photoBytes: _photoBytes,
              isUpdatingPhoto: _isUpdatingPhoto,
              onPickPhoto: _pickPhoto,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                child: Column(
                  children: [
                    _LecturerInformationCard(profile: widget.profile),
                    const SizedBox(height: 14),
                    _LecturerActionsCard(
                      onPickPhoto: _pickPhoto,
                      onChangePassword: () =>
                          context.push(LecturerRoutePaths.changePassword),
                      onLogout: _confirmLogout,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go(LecturerRoutePaths.beranda),
                    icon: const Icon(Icons.arrow_back_ios_new),
                    iconSize: 19,
                    color: colorScheme.primary,
                    tooltip: 'Kembali',
                  ),
                ),
                Text(
                  'Informasi Akun',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _LecturerAvatar(
            photoBytes: photoBytes,
            isUpdating: isUpdatingPhoto,
            onTap: onPickPhoto,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              profile.fullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profile.role.toUpperCase(),
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
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

  static const _avatarSize = 76.0;
  static const _badgeSize = 26.0;

  final Uint8List? photoBytes;
  final bool isUpdating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final photo = photoBytes;

    return Semantics(
      button: true,
      label: 'Ubah foto profil',
      child: SizedBox(
        width: _avatarSize + _badgeSize / 2,
        height: _avatarSize + _badgeSize / 2,
        child: Stack(
          children: [
            Material(
              color: colorScheme.primaryContainer,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: isUpdating ? null : onTap,
                child: SizedBox(
                  width: _avatarSize,
                  height: _avatarSize,
                  child: photo == null
                      ? Icon(
                          Icons.person,
                          size: 48,
                          color: colorScheme.primary.withValues(alpha: 0.35),
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
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _badgeSize,
                height: _badgeSize,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: 13,
                  color: colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _LecturerInformationRow(
            icon: Icons.credit_card_outlined,
            label: 'NIP/NIDN',
            value: profile.staffId,
          ),
          _LecturerInformationRow(
            icon: Icons.mail_outline,
            label: 'Email',
            value: profile.email,
          ),
          _LecturerInformationRow(
            icon: Icons.call_outlined,
            label: 'Nomor HP',
            value: profile.phoneNumber,
          ),
          _LecturerInformationRow(
            icon: Icons.person_outline,
            label: 'Role',
            value: profile.role,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _LecturerInformationRow extends StatelessWidget {
  const _LecturerInformationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
      ],
    );
  }
}

class _LecturerActionsCard extends StatelessWidget {
  const _LecturerActionsCard({
    required this.onPickPhoto,
    required this.onChangePassword,
    required this.onLogout,
  });

  final VoidCallback onPickPhoto;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const neutralIconBackground = Color(0xFFEEEEEE);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _LecturerActionRow(
            key: const ValueKey('lecturer-change-photo'),
            icon: Icons.photo_camera_outlined,
            label: 'Ubah Foto Profil',
            iconBackground: neutralIconBackground,
            iconColor: colorScheme.primary,
            onTap: onPickPhoto,
          ),
          Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
          _LecturerActionRow(
            key: const ValueKey('lecturer-change-password'),
            icon: Icons.key_outlined,
            label: 'Ubah Kata Sandi',
            iconBackground: neutralIconBackground,
            iconColor: colorScheme.primary,
            onTap: onChangePassword,
          ),
          Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
          _LecturerActionRow(
            key: const ValueKey('lecturer-logout'),
            icon: Icons.logout,
            label: 'Keluar',
            iconBackground: colorScheme.errorContainer,
            iconColor: colorScheme.error,
            labelColor: colorScheme.error,
            onTap: onLogout,
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
    required this.iconBackground,
    required this.iconColor,
    this.labelColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconBackground;
  final Color iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor ?? colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
