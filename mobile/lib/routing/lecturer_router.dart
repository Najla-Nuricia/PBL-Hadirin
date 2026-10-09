import 'package:go_router/go_router.dart';

import '../data/dosen/lecturer_profile_preview.dart';
import '../pages/dosen/lecturer_change_password_page.dart';
import '../pages/dosen/lecturer_navigation_shell.dart';
import '../pages/dosen/lecturer_profile_page.dart';
import '../pages/mhs/page_placeholder.dart';
import 'lecturer_route_paths.dart';

final GoRouter lecturerRouter = createLecturerRouter();

GoRouter createLecturerRouter() => GoRouter(
  initialLocation: LecturerRoutePaths.beranda,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return LecturerNavigationShell(
          navigationShell: navigationShell,
          showNavbar: state.uri.path != LecturerRoutePaths.changePassword,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: LecturerRoutePaths.beranda,
              builder: (context, state) =>
                  const StudentPagePlaceholder(title: 'Beranda'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: LecturerRoutePaths.kehadiran,
              builder: (context, state) =>
                  const StudentPagePlaceholder(title: 'Kehadiran'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: LecturerRoutePaths.profil,
              builder: (context, state) =>
                  LecturerProfilePage(profile: lecturerProfilePreview),
              routes: [
                GoRoute(
                  path: 'ubah-kata-sandi',
                  builder: (context, state) =>
                      const LecturerChangePasswordPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
