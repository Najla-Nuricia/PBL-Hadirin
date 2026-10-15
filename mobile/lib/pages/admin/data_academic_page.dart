import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/admin_route_paths.dart';

void _openModule(BuildContext context, String title) {
  switch (title) {
    case 'Tahun Ajaran':
      context.go(AdminRoutePaths.tahunAjaran);
      break;
    case 'Kelas':
      context.go(AdminRoutePaths.tambahKelas);
      break;
    case 'Ruangan':
      context.go(AdminRoutePaths.tambahRuangan);
      break;
    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Halaman $title akan segera tersedia'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class DataAcademicPage extends StatelessWidget {
  const DataAcademicPage({super.key});

  static const _masterData = [
    (
      icon: Icons.calendar_month_outlined,
      title: 'Tahun Ajaran',
      subtitle: 'Kelola periode akademik',
      color: Color(0xFF0099E5),
      background: Color(0xFFEAF7FF),
    ),
    (
      icon: Icons.menu_book_outlined,
      title: 'Mata Kuliah',
      subtitle: 'Tambah, ubah, hapus mata kuliah',
      color: Color(0xFF5B4BFF),
      background: Color(0xFFF0EEFF),
    ),
    (
      icon: Icons.people_outline,
      title: 'Dosen',
      subtitle: 'Kelola data dosen pengampu',
      color: Color(0xFF00B887),
      background: Color(0xFFE8FAF4),
    ),
    (
      icon: Icons.groups_outlined,
      title: 'Kelas',
      subtitle: 'Kelola data kelas per program studi',
      color: Color(0xFFFF9D00),
      background: Color(0xFFFFF6E6),
    ),
    (
      icon: Icons.meeting_room_outlined,
      title: 'Ruangan',
      subtitle: 'Kelola data ruangan',
      color: Color(0xFFFF4567),
      background: Color(0xFFFFEDF0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 50,
              width: double.infinity,
              color: colorScheme.surface,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Data Akademik',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pengaturan & Konfigurasi',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                children: [
                  _NoticeCard(),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MASTER DATA POKOK',
                              style: TextStyle(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.55,
                                ),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pilih modul yang akan dikelola',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_masterData.length} Modul',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final item in _masterData) ...[
                    _MasterDataCard(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                      color: item.color,
                      background: item.background,
                      onTap: () => _openModule(context, item.title),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF1A500);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.error_outline, color: accent, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perhatian Pengisian',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Perubahan master data mempengaruhi modul absensi '
                  'dan jadwal perkuliahan semester aktif.',
                  style: TextStyle(
                    color: const Color(0xFFB45309).withValues(alpha: 0.9),
                    fontSize: 9,
                    height: 1.4,
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

class _MasterDataCard extends StatelessWidget {
  const _MasterDataCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 63,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: colorScheme.onSurface.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.primary.withValues(alpha: 0.55),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
