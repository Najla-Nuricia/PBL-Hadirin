import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mhs/dummy_student_auth_repository.dart';
import '../../../routing/student_router.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  static const _demoEmail = 'ahmad.fauzi@student.polinema.ac.id';
  static const _demoPhone = '0812 3456 7890';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final account = DummyStudentAuthRepository.demoAccount;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Container(
              height: 52,
              color: colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: colorScheme.onSurfaceVariant,
                    onPressed: () => context.go(StudentRoutePaths.beranda),
                    tooltip: 'Kembali',
                  ),
                  Text(
                    'Informasi Akun',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Avatar & Name card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 44,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            account.fullName,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
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
                              'MAHASISWA',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Info card
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.badge_outlined,
                            label: 'NIM/NIDN',
                            value: account.nim,
                            colorScheme: colorScheme,
                          ),
                          _Divider(colorScheme: colorScheme),
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _demoEmail,
                            colorScheme: colorScheme,
                          ),
                          _Divider(colorScheme: colorScheme),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Nomor HP',
                            value: _demoPhone,
                            colorScheme: colorScheme,
                          ),
                          _Divider(colorScheme: colorScheme),
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: 'Role',
                            value: 'Mahasiswa',
                            colorScheme: colorScheme,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Actions card
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _ActionRow(
                            icon: Icons.manage_accounts_outlined,
                            iconColor: colorScheme.primary,
                            iconBg: colorScheme.primaryContainer,
                            label: 'Ubah Profil',
                            colorScheme: colorScheme,
                            onTap: () {},
                          ),
                          _Divider(colorScheme: colorScheme),
                          _ActionRow(
                            icon: Icons.key_outlined,
                            iconColor: const Color(0xFFF5A623),
                            iconBg: const Color(0xFFFEF3C7),
                            label: 'Ubah Kata Sandi',
                            colorScheme: colorScheme,
                            onTap: () {},
                          ),
                          _Divider(colorScheme: colorScheme),
                          _ActionRow(
                            icon: Icons.logout,
                            iconColor: colorScheme.error,
                            iconBg: colorScheme.errorContainer,
                            label: 'Keluar',
                            labelColor: colorScheme.error,
                            colorScheme: colorScheme,
                            showChevron: false,
                            onTap: () => _showLogoutDialog(context, colorScheme),
                            isLast: true,
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

  void _showLogoutDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(StudentRoutePaths.login);
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Info Row widget
// ─────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isLast ? 14 : 14, 16, isLast ? 14 : 14),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 14),
          Column(
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Action Row widget
// ─────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.colorScheme,
    required this.onTap,
    this.labelColor,
    this.showChevron = true,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final Color? labelColor;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final bool showChevron;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isLast ? Radius.zero : Radius.zero,
        bottom: isLast ? const Radius.circular(14) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Divider helper
// ─────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: colorScheme.outlineVariant,
      indent: 16,
      endIndent: 16,
    );
  }
}
