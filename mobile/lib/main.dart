import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/admin/tahun_ajaran_list_page.dart';
import 'pages/admin/tambah_tahun_ajaran_page.dart';
import 'data/mhs/student_account.dart';
import 'pages/mhs/absensi_page.dart';
import 'pages/mhs/auth/student_face_scan_page.dart';
import 'pages/mhs/auth/student_login_page.dart';
import 'pages/mhs/auth/student_register_page.dart';
import 'pages/mhs/beranda_page.dart';
import 'pages/mhs/page_placeholder.dart';
import 'pages/mhs/profil_page.dart';
import 'pages/mhs/surat_page.dart';
import 'pages/mhs/student_navigation_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HadirinApp());
}

class HadirinApp extends StatelessWidget {
  const HadirinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hadirin',
      theme: AppTheme.light,
      routerConfig: _appRouter,
    );
  }
}

/// Combined router untuk semua role (mahasiswa & admin).
final _appRouter = GoRouter(
  initialLocation: '/mhs/login',
  routes: [
    // ── Mahasiswa routes ─────────────────────────────────
    GoRoute(
      path: '/mhs/login',
      builder: (context, state) => const StudentLoginPage(),
    ),
    GoRoute(
      path: '/mhs/register',
      builder: (context, state) => const StudentRegisterPage(),
      routes: [
        GoRoute(
          path: 'scan-wajah',
          redirect: (context, state) =>
              state.extra is StudentRegistrationDraft
                  ? null
                  : '/mhs/register',
          builder: (context, state) => StudentFaceScanPage(
            draft: state.extra! as StudentRegistrationDraft,
          ),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          StudentNavigationShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mhs/beranda',
              builder: (context, state) => const BerandaPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mhs/riwayat',
              builder: (context, state) =>
                  const StudentPagePlaceholder(title: 'Riwayat'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mhs/absensi',
              builder: (context, state) => const AbsensiPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mhs/surat',
              builder: (context, state) => const SuratPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mhs/profil',
              builder: (context, state) => const ProfilPage(),
            ),
          ],
        ),
      ],
    ),

    // ── Admin routes ─────────────────────────────────────
    GoRoute(
      path: '/admin/tahun-ajaran',
      builder: (context, state) => const TahunAjaranListPage(),
      routes: [
        GoRoute(
          path: 'tambah',
          builder: (context, state) => const TambahTahunAjaranPage(),
        ),
      ],
    ),
  ],
);
