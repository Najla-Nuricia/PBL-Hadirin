import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/data/admin/jadwal.dart';
import 'package:mobile/routing/admin_router.dart';
import 'package:mobile/theme/app_theme.dart';

void main() {
  late GoRouter router;

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

  Future<void> pickFromSheet(
    WidgetTester tester, {
    required String fieldHint,
    required String option,
  }) async {
    await tapVisible(tester, find.text(fieldHint));
    await tester.enterText(find.byType(TextField).last, option);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> pickFromDropdown(
    WidgetTester tester, {
    required Finder field,
    required String option,
  }) async {
    final dropdown = find
        .ancestor(
          of: field,
          matching: find.byWidgetPredicate(
            (widget) => widget is DropdownButtonFormField,
          ),
          matchRoot: true,
        )
        .first;
    await tapVisible(tester, dropdown);
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  group('Daftar Jadwal', () {
    testWidgets('shows the seeded weekly schedule grouped by day', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.jadwal);

      expect(find.text('Daftar Jadwal'), findsOneWidget);
      expect(find.text('Filter Jadwal'), findsOneWidget);
      expect(find.text('Senin'), findsOneWidget);
      expect(find.text('Pemrograman Web Lanjut'), findsOneWidget);
      expect(find.text('07:50 – 09:30'), findsOneWidget);
      expect(find.text('Ruang J301'), findsOneWidget);
    });

    testWidgets('schedule cards are read-only without an active toggle', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.jadwal);

      expect(find.byType(Switch), findsNothing);
      expect(find.text('Budi Santoso, S.T., M.T.'), findsWidgets);
    });

    testWidgets('a newly added schedule appears without reloading', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.jadwal);
      expect(find.text('Sabtu'), findsNothing);

      jadwalRepository.add(
        JadwalKuliah(
          id: jadwalRepository.generateId(),
          tahunAjaran: '2026/2027',
          mataKuliah: JadwalMasterData.mataKuliah.firstWhere(
            (item) => item.kode == 'TI505',
          ),
          dosen: JadwalMasterData.dosen.last,
          programStudi: JadwalMasterData.programStudi.first,
          kelas: JadwalMasterData.kelas.firstWhere(
            (item) => item.nama == 'TI-3A',
          ),
          ruangan: JadwalMasterData.ruangan.firstWhere(
            (item) => item.kode == 'J302',
          ),
          hari: HariKuliah.sabtu,
          sesiMulai: JadwalMasterData.sesi[10],
          sesiSelesai: JadwalMasterData.sesi[11],
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Sabtu'), 200);

      expect(find.text('Sabtu'), findsOneWidget);
      expect(find.text('16:20 – 18:00'), findsOneWidget);
    });

    testWidgets('filter changes the displayed class and semester', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.jadwal);

      await pickFromDropdown(
        tester,
        field: find.byType(DropdownButtonFormField<int>),
        option: '1',
      );
      await tapVisible(tester, find.text('Tampilkan Jadwal'));

      expect(find.text('Matematika Dasar'), findsOneWidget);
      expect(find.text('Pemrograman Web Lanjut'), findsNothing);

      await tapVisible(tester, find.text('Genap'));
      await tapVisible(tester, find.text('Tampilkan Jadwal'));

      expect(find.text('Belum ada jadwal untuk filter ini.'), findsOneWidget);
    });
  });

  group('Tambah Jadwal Baru', () {
    testWidgets('shows required errors when saving an empty form', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.tambahJadwal);

      expect(find.text('Tambah Jadwal Baru'), findsOneWidget);
      await tester.tap(find.text('Simpan Jadwal'));
      await tester.pumpAndSettle();

      expect(find.text('Mata kuliah wajib dipilih.'), findsOneWidget);
      expect(find.text('Dosen wajib dipilih.'), findsOneWidget);
      expect(find.text('Kelas wajib dipilih.'), findsOneWidget);

      await pickFromSheet(
        tester,
        fieldHint: 'Cari & Pilih Mata Kuliah...',
        option: 'Struktur Data',
      );

      expect(find.text('Mata kuliah wajib dipilih.'), findsNothing);
      expect(find.text('Dosen wajib dipilih.'), findsOneWidget);
    });

    testWidgets('saves a schedule and rejects a conflicting one', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.tambahJadwal);
      final initialCount = jadwalRepository.getAll().length;

      Future<void> fillForm({required String mataKuliah}) async {
        await pickFromSheet(
          tester,
          fieldHint: 'Cari & Pilih Mata Kuliah...',
          option: mataKuliah,
        );
        await pickFromSheet(
          tester,
          fieldHint: 'Cari Nama/NIP Dosen...',
          option: 'Rizky Pratama, S.Kom., M.T.',
        );
        await pickFromSheet(
          tester,
          fieldHint: 'Cari Kelas (TI-2A)...',
          option: 'TI-1B',
        );
        await pickFromSheet(
          tester,
          fieldHint: 'Cari Ruang (LPR)...',
          option: 'Ruang J302',
        );
        await pickFromDropdown(
          tester,
          field: find.text('Pilih Hari...'),
          option: 'Sabtu',
        );
        await pickFromDropdown(
          tester,
          field: find.text('Sesi').first,
          option: 'Sesi 1 (07:00–07:50)',
        );
        await pickFromDropdown(
          tester,
          field: find.text('Sesi').last,
          option: 'Sesi 2 (07:50–08:40)',
        );
      }

      await fillForm(mataKuliah: 'Struktur Data');
      expect(find.text('Waktu kuliah: 07:00 – 08:40'), findsOneWidget);
      await tester.tap(find.text('Simpan Jadwal'));
      await tester.pumpAndSettle();

      expect(
        find.text('Jadwal Struktur Data untuk TI-1B berhasil disimpan.'),
        findsOneWidget,
      );
      expect(jadwalRepository.getAll(), hasLength(initialCount + 1));
      expect(find.text('Struktur Data'), findsNothing);

      await fillForm(mataKuliah: 'Basis Data');
      await tester.tap(find.text('Simpan Jadwal'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Jadwal bentrok'), findsOneWidget);
      expect(jadwalRepository.getAll(), hasLength(initialCount + 1));
    });

    testWidgets('rejects a class whose level does not match the course', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.tambahJadwal);

      await pickFromSheet(
        tester,
        fieldHint: 'Cari & Pilih Mata Kuliah...',
        option: 'Pemrograman Mobile',
      );
      await pickFromSheet(
        tester,
        fieldHint: 'Cari Kelas (TI-2A)...',
        option: 'TI-1A',
      );
      await tester.tap(find.text('Simpan Jadwal'));
      await tester.pumpAndSettle();

      expect(
        find.text('Pemrograman Mobile (semester 6) untuk tingkat 3.'),
        findsOneWidget,
      );
    });

    testWidgets('searching inside the picker narrows the options', (
      tester,
    ) async {
      await pumpAdminPage(tester, AdminRoutePaths.tambahJadwal);

      await tapVisible(tester, find.text('Cari Nama/NIP Dosen...'));
      await tester.enterText(find.byType(TextField).last, '199002');
      await tester.pumpAndSettle();

      expect(find.text('Rizky Pratama, S.Kom., M.T.'), findsOneWidget);
      expect(find.text('Budi Santoso, S.T., M.T.'), findsNothing);
    });
  });
}
