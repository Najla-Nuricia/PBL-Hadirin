import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/dosen/lecturer_profile.dart';
import '../../routing/lecturer_route_paths.dart';

class LecturerProfilePage extends StatelessWidget {
  const LecturerProfilePage({
    required this.profile,
    super.key,
  });

  final LecturerProfile profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _LecturerProfileHeader(profile: profile),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                child: Column(
                  children: [
                    _LecturerInformationCard(profile: profile),
                    const SizedBox(height: 14),
                    _LecturerActionsCard(
                      onChangePassword: () =>
                          context.push(LecturerRoutePaths.changePassword),
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
  const _LecturerProfileHeader({required this.profile});

  final LecturerProfile profile;

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
          CircleAvatar(
            radius: 33,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 42,
              color: colorScheme.primary.withValues(alpha: 0.25),
            ),
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
  const _LecturerActionsCard({required this.onChangePassword});

  final VoidCallback onChangePassword;

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
          const _LecturerActionRow(
            icon: Icons.person_outline,
            label: 'Ubah Profil',
            iconBackground: Color(0xFFEEEEEE),
            iconColor: Color(0xFF0066FF),
          ),
          Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
          _LecturerActionRow(
            key: const ValueKey('lecturer-change-password'),
            icon: Icons.key_outlined,
            label: 'Ubah Kata Sandi',
            iconBackground: const Color(0xFFEEEEEE),
            iconColor: colorScheme.primary,
            onTap: onChangePassword,
          ),
          Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
          _LecturerActionRow(
            icon: Icons.logout,
            label: 'Keluar',
            iconBackground: colorScheme.errorContainer,
            iconColor: colorScheme.error,
            labelColor: colorScheme.error,
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
