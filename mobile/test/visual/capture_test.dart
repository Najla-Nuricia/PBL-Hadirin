// Harness sementara untuk memeriksa tampilan: merender layar ke PNG.
// Jalankan: flutter test test/visual/capture_test.dart --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/data/mhs/student_account.dart';
import 'package:mobile/data/mhs/student_attendance.dart';
import 'package:mobile/data/mhs/student_data_service.dart';
import 'package:mobile/data/mhs/student_schedule.dart';
import 'package:mobile/models/mhs/student_profile.dart';
import 'package:mobile/pages/onboarding_page.dart';
import 'package:mobile/pages/dosen/widgets/student_attendance_tile.dart';
import 'package:mobile/routing/admin_router.dart';
import 'package:mobile/routing/lecturer_route_paths.dart';
import 'package:mobile/routing/lecturer_router.dart';
import 'package:mobile/routing/student_router.dart';
import 'package:mobile/theme/app_theme.dart';

const _output = String.fromEnvironment(
  'HADIRIN_VISUAL_OUT',
  defaultValue: 'out',
);

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadFont(AppTheme.fontFamily, [
      for (final weight in [
        'Regular',
        'Medium',
        'SemiBold',
        'Bold',
        'ExtraBold',
      ])
        'assets/fonts/PlusJakartaSans-$weight.ttf',
    ]);
    await _loadFont('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
    await _loadFont('packages/phosphor_icons/PhosphorRegular', [
      'packages/phosphor_icons/lib/fonts/Phosphor.ttf',
    ]);
    await _loadFont('packages/phosphor_icons/PhosphorDuotone', [
      'packages/phosphor_icons/lib/fonts/Phosphor-Duotone.ttf',
    ]);
    await _loadFont('packages/phosphor_icons/PhosphorFill', [
      'packages/phosphor_icons/lib/fonts/Phosphor-Fill.ttf',
    ]);
  });

  Future<void> settle(WidgetTester tester) async {
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 4),
      );
    } catch (_) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> shot(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('$_output/$name.png'),
  );

  Future<void> start(WidgetTester tester, GoRouter router) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('mahasiswa', (tester) async {
    final router = createStudentRouter(showOnboarding: true);
    await start(tester, router);
    const routes = {
      'm01-sambutan': StudentRoutePaths.onboarding,
      'm02-peran': StudentRoutePaths.onboardingRole,
      'm03-login': StudentRoutePaths.login,
      'm04-registrasi': StudentRoutePaths.register,
      'm06-beranda': StudentRoutePaths.beranda,
      'm07-riwayat': StudentRoutePaths.riwayat,
      'm08-surat': StudentRoutePaths.surat,
      'm09-profil': StudentRoutePaths.profil,
      'm10-ubah-sandi': StudentRoutePaths.changePassword,
      'm11-presensi': StudentRoutePaths.absensi,
    };
    for (final entry in routes.entries) {
      router.go(entry.value);
      await settle(tester);
      if (entry.key == 'm01-sambutan') {
        // Dekode gambar butuh waktu nyata, di luar jam palsu flutter_test.
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(OnboardingWelcomePage.heroAsset),
            tester.element(find.byType(OnboardingWelcomePage)),
          ),
        );
        await settle(tester);
      }
      await shot(tester, entry.key);
    }

    await tester.tap(find.text('Lanjutkan ke Scan Wajah'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await shot(tester, 'm12-scan-wajah');
    await tester.tap(find.byTooltip('Kembali').last);
    await settle(tester);

    router.go(
      StudentRoutePaths.registerFaceScan,
      extra: const StudentRegistrationDraft(
        fullName: 'Joni Pratama',
        nim: '2341720099',
        className: 'TI-3A',
        password: 'rahasia123',
      ),
    );
    await settle(tester);
    await shot(tester, 'm05-daftar-wajah');
  });

  testWidgets('beranda dengan presensi dibuka', (tester) async {
    final router = createStudentRouter(homeDataService: _StudentHomeData());
    await start(tester, router);
    router.go(StudentRoutePaths.beranda);
    await settle(tester);

    expect(find.text('Halo, Joni.'), findsOneWidget);
    expect(find.text('Presensi dibuka'), findsOneWidget);
    expect(find.text('Berlangsung'), findsOneWidget);
    if (_output != 'out') {
      await shot(tester, 'm13-beranda-presensi');
    }

    await tester.tap(find.byTooltip('Pilih hari jadwal'));
    await settle(tester);
    final nextDay = DateTime.now().weekday % DateTime.daysPerWeek;
    await tester.tap(find.byType(CheckedPopupMenuItem<int>).at(nextDay));
    await settle(tester);
    expect(find.text('Tidak ada kelas'), findsOneWidget);

    await tester.tap(find.text('Mulai presensi'));
    await settle(tester);
    expect(
      router.routeInformationProvider.value.uri.path,
      StudentRoutePaths.absensi,
    );
    expect(find.text('Pindai kode QR'), findsOneWidget);
  });

  testWidgets('dosen', (tester) async {
    final router = createLecturerRouter();
    await start(tester, router);
    final routes = {
      'd01-login': LecturerRoutePaths.login,
      'd02-registrasi': LecturerRoutePaths.register,
      'd03-cek-presensi': LecturerRoutePaths.kehadiran,
      'd04-daftar': LecturerRoutePaths.daftarKehadiran,
      'd06-profil': LecturerRoutePaths.profil,
      'd07-ubah-sandi': LecturerRoutePaths.changePassword,
    };
    for (final entry in routes.entries) {
      router.go(entry.value);
      await settle(tester);
      await shot(tester, entry.key);
    }
    router.go(LecturerRoutePaths.daftarKehadiran);
    await settle(tester);
    await tester.tap(find.byType(StudentAttendanceTile).at(1));
    await settle(tester);
    await shot(tester, 'd05-detail');
  });

  testWidgets('admin', (tester) async {
    final router = createAdminRouter();
    await start(tester, router);
    const routes = {
      'a01-login': AdminRoutePaths.login,
      'a02-data-akademik': AdminRoutePaths.dataAkademik,
      'a03-tambah-jadwal': AdminRoutePaths.tambahJadwal,
      'a04-jadwal': AdminRoutePaths.jadwal,
      'a05-tahun-ajaran': AdminRoutePaths.tahunAjaran,
      'a06-tambah-tahun-ajaran': AdminRoutePaths.tambahTahunAjaran,
      'a07-mata-kuliah': AdminRoutePaths.mataKuliah,
      'a08-tambah-mata-kuliah': AdminRoutePaths.tambahMataKuliah,
      'a09-tambah-kelas': AdminRoutePaths.tambahKelas,
      'a10-tambah-dosen': AdminRoutePaths.tambahDosen,
    };
    for (final entry in routes.entries) {
      router.go(entry.value);
      await settle(tester);
      await shot(tester, entry.key);
    }
  });
}

class _StudentHomeData extends StudentDataService {
  @override
  Future<StudentProfile> loadProfile() async => const StudentProfile(
    fullName: 'Joni Pratama',
    studentId: '2341720001',
    email: '',
    phoneNumber: '',
    role: 'Mahasiswa',
    className: 'TI-3A',
  );

  @override
  Future<StudentAttendanceSummary> loadAttendanceSummary() async =>
      const StudentAttendanceSummary(hadir: 28, izin: 2, sakit: 1, alfa: 1);

  @override
  Future<List<StudentSchedule>> loadSchedules({int? dayOfWeek}) async {
    final day = DateTime.now().weekday;
    return [
      StudentSchedule(
        courseName: 'Pemrograman Mobile',
        startTime: '07.00',
        endTime: '09.30',
        room: 'LSI-1',
        lecturerName: '',
        dayOfWeek: day,
      ),
      StudentSchedule(
        courseName: 'Kecerdasan Buatan',
        startTime: '10.20',
        endTime: '12.00',
        room: 'LPR-2',
        lecturerName: '',
        dayOfWeek: day,
      ),
    ];
  }

  @override
  Future<ClassReminder?> loadClassReminder() async => null;

  @override
  Future<List<Map<String, dynamic>>> loadActiveSessions() async => [
    {
      'matkul_nama': 'Pemrograman Mobile',
      'jam_mulai': '07.00',
      'jam_selesai': '09.30 WIB',
      'ruangan_nama': 'LSI-1',
    },
  ];

  @override
  Future<List<StudentAttendanceRecord>> loadAttendanceHistory({
    String? status,
  }) async => [];
}
