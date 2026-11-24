import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/admin/admin_auth_repository.dart';
import 'package:mobile/data/admin/admin_jadwal_options_service.dart';
import 'package:mobile/data/admin/admin_jadwal_service.dart';
import 'package:mobile/data/admin/admin_master_data_service.dart';
import 'package:mobile/pages/admin/tambah_jadwal_page.dart';

void main() {
  http.Response jsonResponse(Map<String, dynamic> body, [int status = 200]) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'Content-Type': 'application/json'},
      );

  http.Response optionsResponse(List<Map<String, dynamic>> data) =>
      jsonResponse({'data': data, 'total': data.length});

  Map<String, dynamic> createdJadwal() => {
    'id': 'jadwal-baru',
    'tahun_ajaran_id': 'ta-1',
    'tahun_ajaran': '2026/2027',
    'semester': 'genap',
    'hari': 'sabtu',
    'sesi_mulai': 1,
    'sesi_selesai': 2,
    'jam_mulai': '07:00',
    'jam_selesai': '08:40',
    'mata_kuliah_kode': 'TI201',
    'matkul_nama': 'Struktur Data',
    'sks': 3,
    'dosen_nip': '199002202015041003',
    'dosen_nama': 'Rizky Pratama, S.Kom., M.T.',
    'program_studi_kode': 'D4-TI',
    'prodi_nama': 'D4 Teknik Informatika',
    'kelas_id': 'kelas-2',
    'kelas_nama': 'TI-1B',
    'kelas_tingkat': 1,
    'ruangan_kode': 'J302',
    'ruangan_nama': 'Ruang J302',
  };

  MockClient buildClient({
    required http.Response Function(http.Request request) onJadwal,
    List<String>? seenPaths,
    bool Function()? failTahunAjaran,
  }) {
    return MockClient((request) async {
      seenPaths?.add(request.url.path);
      return switch (request.url.path) {
        '/admin/jadwal' => onJadwal(request),
        '/admin/tahun-ajaran' when failTahunAjaran?.call() == true =>
          jsonResponse({'detail': 'Gagal memuat tahun ajaran.'}, 500),
        '/admin/tahun-ajaran' => optionsResponse([
          {
            'id': 'ta-1',
            'tahun': '2026/2027',
            'status': 'aktif',
            'semester_ganjil': true,
            'semester_genap': true,
          },
        ]),
        '/admin/mata-kuliah' => optionsResponse([
          {'kode': 'TI201', 'nama': 'Struktur Data', 'semester': 2, 'sks': 3},
        ]),
        '/admin/dosen' => optionsResponse([
          {
            'nip': '199002202015041003',
            'nama': 'Rizky Pratama, S.Kom., M.T.',
            'email': 'rizky@polinema.ac.id',
          },
        ]),
        '/admin/program-studi' => optionsResponse([
          {'kode': 'D4-TI', 'nama': 'D4 Teknik Informatika'},
        ]),
        '/admin/ruangan' => optionsResponse([
          {'kode': 'J302', 'nama': 'Ruang J302'},
        ]),
        '/admin/sesi-kuliah' => optionsResponse([
          {'nomor': 1, 'jam_mulai': '07:00', 'jam_selesai': '07:50'},
          {'nomor': 2, 'jam_mulai': '07:50', 'jam_selesai': '08:40'},
        ]),
        '/kelas' => optionsResponse([
          {
            'id': 'kelas-2',
            'nama': 'TI-1B',
            'tingkat': 1,
            'program_studi_kode': 'D4-TI',
            'tahun_ajaran_id': 'ta-1',
          },
        ]),
        _ => fail('Endpoint tak terduga: ${request.url.path}'),
      };
    });
  }

  Future<void> pumpForm(WidgetTester tester, MockClient client) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    adminAuthRepository.currentAccessToken = 'jwt-admin';
    addTearDown(adminAuthRepository.logout);

    await tester.pumpWidget(
      MaterialApp(
        home: TambahJadwalPage(
          service: AdminJadwalService(
            tokenProvider: () => 'jwt-admin',
            httpClient: client,
          ),
          optionsService: AdminJadwalOptionsService(
            masterData: AdminMasterDataService(
              tokenProvider: () => 'jwt-admin',
              httpClient: client,
            ),
          ),
        ),
      ),
    );
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

  Future<void> fillAcademicAndPlace(WidgetTester tester) async {
    await pickFromSheet(
      tester,
      fieldHint: 'Cari & Pilih Mata Kuliah...',
      option: 'Struktur Data',
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
  }

  testWidgets('menolak sesi selesai yang lebih awal dari sesi mulai', (
    tester,
  ) async {
    final paths = <String>[];
    final client = buildClient(
      seenPaths: paths,
      onJadwal: (_) => fail('Jadwal tidak boleh dikirim saat validasi gagal.'),
    );
    await pumpForm(tester, client);

    await fillAcademicAndPlace(tester);
    await pickFromDropdown(
      tester,
      field: find.text('Sesi').first,
      option: 'Sesi 2 (07:50–08:40)',
    );
    await pickFromDropdown(
      tester,
      field: find.text('Sesi').last,
      option: 'Sesi 1 (07:00–07:50)',
    );
    await tapVisible(tester, find.text('Simpan Jadwal'));

    expect(find.text('Harus setelah sesi mulai.'), findsOneWidget);
    expect(paths, isNot(contains('/admin/jadwal')));
    expect(find.text('Tambah Jadwal Baru'), findsOneWidget);
  });

  testWidgets('menampilkan detail konflik backend dan tetap di form', (
    tester,
  ) async {
    final client = buildClient(
      onJadwal: (_) => jsonResponse({
        'detail': 'Kelas TI-1B sudah memiliki jadwal pada hari sabtu sesi 1-2.',
        'code': 'conflict',
      }, 409),
    );
    await pumpForm(tester, client);

    await fillAcademicAndPlace(tester);
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
    await tapVisible(tester, find.text('Simpan Jadwal'));

    expect(
      find.text('Kelas TI-1B sudah memiliki jadwal pada hari sabtu sesi 1-2.'),
      findsOneWidget,
    );
    expect(find.textContaining('berhasil disimpan'), findsNothing);
    expect(find.text('Tambah Jadwal Baru'), findsOneWidget);
  });

  testWidgets('gagal memuat pilihan form bisa diRetry sebelum menyimpan', (
    tester,
  ) async {
    var failTahunAjaran = true;
    final client = buildClient(
      failTahunAjaran: () => failTahunAjaran,
      onJadwal: (_) => jsonResponse({
        'message': 'Jadwal berhasil dibuat.',
        'data': createdJadwal(),
      }, 201),
    );
    await pumpForm(tester, client);

    expect(find.text('Gagal memuat tahun ajaran.'), findsOneWidget);
    final saveButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Simpan Jadwal'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(saveButton.onPressed, isNull);

    failTahunAjaran = false;
    await tapVisible(tester, find.text('Coba lagi'));

    expect(find.text('Gagal memuat tahun ajaran.'), findsNothing);
    expect(find.text('Cari & Pilih Mata Kuliah...'), findsOneWidget);
    final enabledButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Simpan Jadwal'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(enabledButton.onPressed, isNotNull);
  });
}
