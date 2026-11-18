import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/data/admin/dosen.dart';
import 'package:mobile/data/admin/jadwal.dart';
import 'package:mobile/data/admin/kelas.dart';
import 'package:mobile/data/admin/ruangan.dart';
import 'package:mobile/routing/admin_router.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  late GoRouter router;

  setUp(() {
    kelasRepository.reset([]);
    ruanganRepository.reset([]);
    dosenRepository.reset([]);
  });

  tearDown(() {
    kelasRepository.reset();
    ruanganRepository.reset();
    dosenRepository.reset();
  });

  Future<void> pumpAdminPage(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    router = createAdminRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: AppTheme.light),
    );
    router.go(path);
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Tunggu SnackBar hilang agar tidak menghalangi tombol di bagian bawah.
  Future<void> closeSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  group('Modul Kelas CRUD', () {
    testWidgets('create, update, delete kelas dari halaman daftar', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.kelas);

      // READ: halaman daftar tampil dengan empty state karena data dikosongkan.
      expect(find.text('Kelola data kelas per program studi'), findsOneWidget);
      expect(find.text('Belum ada data kelas.'), findsOneWidget);

      // CREATE
      await tapVisible(tester, find.text('Tambah'));
      expect(find.text('Tambah Kelas'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'TI-3F');
      await tester.enterText(fields.at(1), '26');
      await tapVisible(tester, find.text('Simpan'));

      expect(kelasRepository.getAll(), hasLength(1));
      expect(kelasRepository.getAll().single.nama, 'TI-3F');
      expect(find.text('TI-3F'), findsOneWidget);
      expect(find.textContaining('26 mahasiswa'), findsOneWidget);

      // UPDATE
      await closeSnackBar(tester);
      await tapVisible(tester, find.byIcon(Icons.edit_outlined).first);
      expect(find.text('Ubah Kelas'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'TI-3G');
      await tapVisible(tester, find.text('Simpan Perubahan'));

      expect(kelasRepository.getAll().single.nama, 'TI-3G');
      expect(find.text('TI-3G'), findsOneWidget);
      expect(find.text('TI-3F'), findsNothing);

      // DELETE (dialog Batal dulu, data harus tetap ada)
      await closeSnackBar(tester);
      await tapVisible(tester, find.byIcon(Icons.delete_outline_rounded).first);
      expect(find.text('Hapus Kelas'), findsOneWidget);
      await tapVisible(tester, find.text('Batal'));
      expect(kelasRepository.getAll(), hasLength(1));

      await tapVisible(tester, find.byIcon(Icons.delete_outline_rounded).first);
      await tapVisible(tester, find.text('Hapus'));

      expect(kelasRepository.getAll(), isEmpty);
      expect(find.text('Belum ada data kelas.'), findsOneWidget);
    });

    testWidgets('search menyaring daftar kelas', (tester) async {
      kelasRepository.reset(const [
        Kelas(
          id: 'k1',
          tahunAjaran: '2026/2027',
          programStudi: 'D4 Teknik Informatika',
          nama: 'TI-3A',
          kapasitas: 30,
          status: KelasStatus.aktif,
        ),
        Kelas(
          id: 'k2',
          tahunAjaran: '2026/2027',
          programStudi: 'D4 Sistem Informasi Bisnis',
          nama: 'SIB-2C',
          kapasitas: 28,
          status: KelasStatus.nonAktif,
        ),
      ]);

      await pumpAdminPage(tester, AdminRoutePaths.kelas);
      expect(find.text('TI-3A'), findsOneWidget);
      expect(find.text('SIB-2C'), findsOneWidget);
      expect(find.text('Non-Aktif'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'SIB');
      await tester.pumpAndSettle();

      expect(find.text('TI-3A'), findsNothing);
      expect(find.text('SIB-2C'), findsOneWidget);
    });

    testWidgets('validasi menolak nama kelas duplikat', (tester) async {
      kelasRepository.reset([
        const Kelas(
          id: 'k1',
          // Samakan dengan tahun ajaran aktif (default dropdown form).
          tahunAjaran: '2026/2027',
          programStudi: 'D4 Teknik Informatika',
          nama: 'TI-3A',
          kapasitas: 30,
          status: KelasStatus.aktif,
        ),
      ]);

      await pumpAdminPage(tester, AdminRoutePaths.tambahKelas);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'TI-3A');
      await tester.enterText(fields.at(1), '30');
      await tapVisible(tester, find.text('Simpan'));

      expect(kelasRepository.getAll(), hasLength(1));
      expect(find.textContaining('sudah ada di tahun ajaran'), findsOneWidget);
    });
  });

  group('Modul Ruangan CRUD', () {
    testWidgets('create, update, delete ruangan dari halaman daftar', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.ruangan);

      expect(find.text('Kelola data ruangan'), findsOneWidget);
      expect(find.text('Belum ada data ruangan.'), findsOneWidget);

      // CREATE
      await tapVisible(tester, find.text('Tambah'));
      expect(find.text('Tambah Ruangan'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'lpr1');
      await tester.enterText(fields.at(1), 'Lab Pemrograman 1');
      await tester.enterText(fields.at(2), '40');
      await tapVisible(tester, find.text('Simpan'));

      expect(ruanganRepository.getAll(), hasLength(1));
      expect(ruanganRepository.getAll().single.kode, 'LPR1');
      expect(find.text('Lab Pemrograman 1'), findsOneWidget);
      expect(find.textContaining('Kapasitas 40 orang'), findsOneWidget);

      // UPDATE
      await closeSnackBar(tester);
      await tapVisible(tester, find.byIcon(Icons.edit_outlined).first);
      expect(find.text('Ubah Ruangan'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Lab Pemrograman 2',
      );
      await tapVisible(tester, find.text('Simpan Perubahan'));

      expect(ruanganRepository.getAll().single.nama, 'Lab Pemrograman 2');
      expect(ruanganRepository.getAll().single.kode, 'LPR1');
      expect(find.text('Lab Pemrograman 2'), findsOneWidget);

      // DELETE
      await closeSnackBar(tester);
      await tapVisible(tester, find.byIcon(Icons.delete_outline_rounded).first);
      expect(find.text('Hapus Ruangan'), findsOneWidget);
      await tapVisible(tester, find.text('Hapus'));

      expect(ruanganRepository.getAll(), isEmpty);
      expect(find.text('Belum ada data ruangan.'), findsOneWidget);
    });

    testWidgets('validasi menolak kode ruangan duplikat', (tester) async {
      ruanganRepository.reset(const [
        Ruangan(kode: 'LPR1', nama: 'Lab Pemrograman 1'),
      ]);

      await pumpAdminPage(tester, AdminRoutePaths.tambahRuangan);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'LPR1');
      await tester.enterText(fields.at(1), 'Lab Lain');
      await tapVisible(tester, find.text('Simpan'));

      expect(ruanganRepository.getAll(), hasLength(1));
      expect(find.textContaining('sudah terdaftar'), findsOneWidget);
    });
  });

  group('Modul Dosen CRUD', () {
    testWidgets('create, update, delete dosen dari halaman daftar', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.dosen);

      expect(find.text('Kelola data dosen pengampu'), findsOneWidget);
      expect(find.text('Belum ada data dosen.'), findsOneWidget);

      // CREATE
      await tapVisible(tester, find.text('Tambah'));
      expect(find.text('Tambah Dosen'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '198001');
      await tester.enterText(fields.at(1), 'Dr. Ani Suryani');
      await tester.enterText(fields.at(2), 'ani@polinema.ac.id');
      await tapVisible(tester, find.text('Simpan'));

      expect(dosenRepository.getAll(), hasLength(1));
      expect(dosenRepository.getAll().single.nip, '198001');
      expect(find.text('Dr. Ani Suryani'), findsOneWidget);
      expect(find.textContaining('NIP 198001'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);

      // UPDATE
      await closeSnackBar(tester);
      await tapVisible(tester, find.byIcon(Icons.edit_outlined).first);
      expect(find.text('Ubah Dosen'), findsOneWidget);
      // Field harus terisi data lama.
      expect(find.text('Dr. Ani Suryani'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Dr. Ani Suryani, M.Kom',
      );
      await tapVisible(tester, find.text('Simpan'));

      expect(dosenRepository.getAll().single.nama, 'Dr. Ani Suryani, M.Kom');
      expect(find.text('Dr. Ani Suryani, M.Kom'), findsOneWidget);

      // DELETE
      await closeSnackBar(tester);
      await tapVisible(tester, find.byIcon(Icons.delete_outline_rounded).first);
      expect(find.text('Hapus Dosen'), findsOneWidget);
      await tapVisible(tester, find.text('Hapus'));

      expect(dosenRepository.getAll(), isEmpty);
      expect(find.text('Belum ada data dosen.'), findsOneWidget);
    });

    testWidgets('validasi menolak NIP duplikat', (tester) async {
      dosenRepository.reset(const [Dosen(nip: '198001', nama: 'Dr. Ani')]);

      await pumpAdminPage(tester, AdminRoutePaths.tambahDosen);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '198001');
      await tester.enterText(fields.at(1), 'Dosen Baru');
      await tapVisible(tester, find.text('Simpan'));

      expect(dosenRepository.getAll(), hasLength(1));
      expect(find.textContaining('sudah terdaftar'), findsOneWidget);
    });
  });

  group('Navigasi data akademik', () {
    testWidgets('modul Kelas/Ruangan/Dosen membuka halaman daftar', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.dataAkademik);

      await tapVisible(tester, find.text('Kelas'));
      expect(
        router.routeInformationProvider.value.uri.path,
        AdminRoutePaths.kelas,
      );
      await tapVisible(tester, find.byIcon(Icons.arrow_back_ios_new_rounded));

      await tapVisible(tester, find.text('Ruangan'));
      expect(
        router.routeInformationProvider.value.uri.path,
        AdminRoutePaths.ruangan,
      );
      await tapVisible(tester, find.byIcon(Icons.arrow_back_ios_new_rounded));

      await tapVisible(tester, find.text('Dosen'));
      expect(
        router.routeInformationProvider.value.uri.path,
        AdminRoutePaths.dosen,
      );
    });
  });
}
