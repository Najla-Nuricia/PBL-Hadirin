import 'package:go_router/go_router.dart';

import '../data/mhs/student_account.dart';
import '../data/mhs/student_profile_preview.dart';
import '../pages/admin/admin_navigation_shell.dart';
import '../pages/admin/auth/admin_login_page.dart';
import '../pages/admin/data_academic_page.dart';
import '../pages/admin/jadwal_list_page.dart';
import '../pages/admin/tahun_ajaran_list_page.dart';
import '../pages/admin/tambah_jadwal_page.dart';
import '../pages/admin/tambah_kelas_page.dart';
import '../pages/admin/tambah_ruangan_page.dart';
import '../pages/admin/tambah_tahun_ajaran_page.dart';
import '../pages/mhs/absensi_page.dart';
import '../pages/mhs/auth/student_face_scan_page.dart';
import '../pages/mhs/auth/student_login_page.dart';
import '../pages/mhs/auth/student_register_page.dart';
import '../pages/mhs/beranda_page.dart';
import '../pages/mhs/change_password_page.dart';
import '../pages/mhs/page_placeholder.dart';
import '../pages/mhs/profile_page.dart';
import '../pages/mhs/student_navigation_shell.dart';
import '../pages/onboarding_page.dart';
import '../pages/mhs/surat_page.dart';
import 'admin_route_paths.dart';
import 'student_route_paths.dart';

export 'student_route_paths.dart';

final GoRouter studentRouter = createStudentRouter();

GoRouter createStudentRouter({bool showOnboarding = false}) => GoRouter(
  initialLocation: showOnboarding
      ? StudentRoutePaths.onboarding
      : StudentRoutePaths.login,
  routes: [
    GoRoute(
      path: StudentRoutePaths.onboarding,
      builder: (context, state) => const OnboardingWelcomePage(),
      routes: [
        GoRoute(
          path: 'peran',
          builder: (context, state) => OnboardingRolePage(
            onStudentPressed: () => context.go(StudentRoutePaths.login),
            onAdminPressed: () => context.go(AdminRoutePaths.login),
          ),
        ),
      ],
    ),
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
    GoRoute(
      path: AdminRoutePaths.tambahRuangan,
      builder: (context, state) => const TambahRuanganPage(),
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
              builder: (context, state) => ProfilePage(
                profile: studentProfilePreview,
                onChangePassword: () =>
                    context.push(StudentRoutePaths.changePassword),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: StudentRoutePaths.changePassword,
      builder: (context, state) => const ChangePasswordPage(),
    ),
  ],
);
