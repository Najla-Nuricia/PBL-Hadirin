import 'package:go_router/go_router.dart';

import '../data/mhs/student_account.dart';
import '../pages/mhs/absensi_page.dart';
import '../pages/mhs/auth/student_face_scan_page.dart';
import '../pages/mhs/auth/student_login_page.dart';
import '../pages/mhs/auth/student_register_page.dart';
import '../pages/mhs/beranda_page.dart';
import '../pages/mhs/page_placeholder.dart';
import '../pages/mhs/profil_page.dart';
import '../pages/mhs/surat_page.dart';
import '../pages/mhs/student_navigation_shell.dart';

final studentRouter = createStudentRouter();

GoRouter createStudentRouter() => GoRouter(
  initialLocation: StudentRoutePaths.login,
  routes: [
    GoRoute(
      path: StudentRoutePaths.login,
      builder: (context, state) => const StudentLoginPage(),
    ),
    GoRoute(
      path: StudentRoutePaths.register,
      builder: (context, state) => const StudentRegisterPage(),
      routes: [
        GoRoute(
          path: StudentRoutePaths.registerFaceScanSegment,
          redirect: (context, state) => state.extra is StudentRegistrationDraft
              ? null
              : StudentRoutePaths.register,
          builder: (context, state) => StudentFaceScanPage(
            draft: state.extra! as StudentRegistrationDraft,
          ),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return StudentNavigationShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: StudentRoutePaths.beranda,
              builder: (context, state) => const BerandaPage(),
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
              builder: (context, state) => const AbsensiPage(),
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
              builder: (context, state) => const ProfilPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

abstract final class StudentRoutePaths {
  static const login = '/mhs/login';
  static const register = '/mhs/register';
  static const registerFaceScanSegment = 'scan-wajah';
  static const registerFaceScan = '$register/$registerFaceScanSegment';
  static const beranda = '/mhs/beranda';
  static const riwayat = '/mhs/riwayat';
  static const absensi = '/mhs/absensi';
  static const surat = '/mhs/surat';
  static const profil = '/mhs/profil';
}
