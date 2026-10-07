import 'package:go_router/go_router.dart';

import '../data/mhs/student_profile_preview.dart';
import '../pages/mhs/change_password_page.dart';
import '../pages/mhs/page_placeholder.dart';
import '../pages/mhs/profile_page.dart';
import '../pages/mhs/surat_page.dart';
import '../pages/mhs/student_navigation_shell.dart';

final GoRouter studentRouter = GoRouter(
  initialLocation: StudentRoutePaths.beranda,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return StudentNavigationShell(
          navigationShell: navigationShell,
          showNavbar: state.uri.path != StudentRoutePaths.changePassword,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: StudentRoutePaths.beranda,
              builder: (context, state) =>
                  const StudentPagePlaceholder(title: 'Beranda'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: StudentRoutePaths.riwayat,
              builder: (context, state) =>
                  const StudentPagePlaceholder(title: 'Riwayat'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: StudentRoutePaths.absensi,
              builder: (context, state) =>
                  const StudentPagePlaceholder(title: 'Absensi'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: StudentRoutePaths.surat,
              builder: (context, state) => const SuratPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: StudentRoutePaths.profil,
              builder: (context, state) => ProfilePage(
                profile: studentProfilePreview,
                onChangePassword: () =>
                    studentRouter.go(StudentRoutePaths.changePassword),
              ),
              routes: [
                GoRoute(
                  path: 'ubah-kata-sandi',
                  builder: (context, state) => const ChangePasswordPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

abstract final class StudentRoutePaths {
  static const beranda = '/mhs/beranda';
  static const riwayat = '/mhs/riwayat';
  static const absensi = '/mhs/absensi';
  static const surat = '/mhs/surat';
  static const profil = '/mhs/profil';
  static const changePassword = '/mhs/profil/ubah-kata-sandi';
}
