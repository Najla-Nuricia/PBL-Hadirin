import 'package:go_router/go_router.dart';

import '../pages/admin/admin_navigation_shell.dart';
import '../pages/admin/admin_placeholder_page.dart';
import '../pages/admin/auth/admin_login_page.dart';
import '../pages/admin/data_academic_page.dart';
import 'admin_route_paths.dart';

final GoRouter adminRouter = createAdminRouter();

GoRouter createAdminRouter() => GoRouter(
  initialLocation: AdminRoutePaths.login,
  routes: [
    GoRoute(
      path: AdminRoutePaths.login,
      builder: (context, state) => const AdminLoginPage(),
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
              builder: (context, state) =>
                  const AdminPlaceholderPage(title: 'Tambah Jadwal'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AdminRoutePaths.jadwal,
              builder: (context, state) =>
                  const AdminPlaceholderPage(title: 'Jadwal'),
            ),
          ],
        ),
      ],
    ),
  ],
);
