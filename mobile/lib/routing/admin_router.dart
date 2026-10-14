import 'package:go_router/go_router.dart';

import '../pages/admin/admin_navigation_shell.dart';
import '../pages/admin/auth/admin_login_page.dart';
import '../pages/admin/data_academic_page.dart';
import '../pages/admin/jadwal_list_page.dart';
import '../pages/admin/tahun_ajaran_list_page.dart';
import '../pages/admin/tambah_jadwal_page.dart';
import '../pages/admin/tambah_tahun_ajaran_page.dart';
import '../pages/admin/tambah_kelas_page.dart';
import 'admin_route_paths.dart';

export 'admin_route_paths.dart';

final GoRouter adminRouter = createAdminRouter();

GoRouter createAdminRouter() => GoRouter(
  initialLocation: AdminRoutePaths.login,
  routes: [
    GoRoute(
      path: AdminRoutePaths.login,
      builder: (context, state) => const AdminLoginPage(),
    ),
    GoRoute(
      path: AdminRoutePaths.tahunAjaran,
      builder: (context, state) => const TahunAjaranListPage(),
      routes: [
        GoRoute(
          path: AdminRoutePaths.tambahTahunAjaranSegment,
          builder: (context, state) => const TambahTahunAjaranPage(),
        ),
      ],
    ),
    GoRoute(
      path: AdminRoutePaths.tambahKelas,
      builder: (context, state) => const TambahKelasPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AdminNavigationShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AdminRoutePaths.dataAkademik,
              builder: (context, state) => const DataAcademicPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AdminRoutePaths.tambahJadwal,
              builder: (context, state) => const TambahJadwalPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AdminRoutePaths.jadwal,
              builder: (context, state) => const JadwalListPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
