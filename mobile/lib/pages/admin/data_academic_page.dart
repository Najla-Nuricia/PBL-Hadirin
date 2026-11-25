import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/admin_list.dart';
import 'widgets/admin_scaffold.dart';

void _openModule(BuildContext context, String title) {
  switch (title) {
    case 'Tahun Ajaran':
      context.go(AdminRoutePaths.tahunAjaran);
      break;
    case 'Kelas':
      context.go(AdminRoutePaths.kelas);
      break;
    case 'Ruangan':
      context.go(AdminRoutePaths.ruangan);
      break;
    case 'Mata Kuliah':
      context.go(AdminRoutePaths.mataKuliah);
      break;
    case 'Dosen':
      context.go(AdminRoutePaths.dosen);
      break;
    case 'Whitelist NIM':
      context.go(AdminRoutePaths.whitelistNim);
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
      icon: PhosphorIconsRegular.calendarBlank,
      title: 'Tahun Ajaran',
      subtitle: 'Kelola periode akademik',
    ),
    (
      icon: PhosphorIconsRegular.bookOpen,
      title: 'Mata Kuliah',
      subtitle: 'Tambah, ubah, hapus mata kuliah',
    ),
    (
      icon: PhosphorIconsRegular.users,
      title: 'Dosen',
      subtitle: 'Kelola data dosen pengampu',
    ),
    (
      icon: PhosphorIconsRegular.usersThree,
      title: 'Kelas',
      subtitle: 'Kelola data kelas per program studi',
    ),
    (
      icon: PhosphorIconsRegular.door,
      title: 'Ruangan',
      subtitle: 'Kelola data ruangan',
    ),
    (
      icon: PhosphorIconsRegular.shieldCheck,
      title: 'Whitelist NIM',
      subtitle: 'Kelola NIM yang diizinkan registrasi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AdminPageScaffold(
      title: 'Data Akademik',
      description: 'Sekretaris Jurusan Teknologi Informasi',
      children: [
        AdminListCard(
          children: [
            AdminListRow(
              icon: PhosphorIconsRegular.calendarBlank,
              title: 'Daftar Jadwal',
              subtitle: 'Lihat jadwal per kelas',
              onTap: () => context.go(AdminRoutePaths.jadwal),
            ),
            AdminListRow(
              icon: PhosphorIconsRegular.plusCircle,
              title: 'Buat jadwal',
              subtitle: 'Atur ruang dan jam kuliah',
              onTap: () => context.go(AdminRoutePaths.tambahJadwal),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const AppBanner(
          tone: StatusTone.warning,
          title: 'Perhatian Pengisian',
          message:
              'Perubahan master data mempengaruhi modul absensi '
              'dan jadwal perkuliahan semester aktif.',
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSectionHeader(
          title: 'Master Data Pokok',
          action: Text(
            '${_masterData.length} Modul',
            style: text.bodySmall?.tabular.copyWith(color: AppColors.inkFaint),
          ),
        ),
        Text(
          'Pilih modul yang akan dikelola',
          style: text.bodySmall?.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        AdminListCard(
          children: [
            for (final item in _masterData)
              AdminListRow(
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
                onTap: () => _openModule(context, item.title),
              ),
          ],
        ),
      ],
    );
  }
}
