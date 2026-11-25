import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/admin/admin_auth_repository.dart';
import 'package:mobile/data/admin/admin_whitelist_nim_service.dart';
import 'package:mobile/data/mhs/dummy_student_auth_repository.dart';
import 'package:mobile/data/mhs/student_data_service.dart';

void main() {
  const testNim = '2341999999';

  /// Backend menolak mahasiswa baru jika NIM belum masuk whitelist admin.
  Future<void> ensureWhitelisted(String nim) async {
    final admin = await adminAuthRepository.login(
      username: 'adminhadirin',
      password: 'admin123',
    );
    expect(
      admin,
      isNotNull,
      reason: 'Login admin untuk menyiapkan whitelist gagal.',
    );
    try {
      await adminWhitelistNimService.create(nim);
    } on AdminRemoteApiException catch (error) {
      if (error.statusCode != 409) rethrow;
    }
  }

  Future<void> removeWhitelisted(String nim) async {
    try {
      await adminWhitelistNimService.delete(nim);
    } on AdminRemoteApiException catch (error) {
      if (error.statusCode != 404) rethrow;
    }
  }

  setUp(() async {
    // Pastikan terautentikasi sebelum tes
    await studentAuthRepository.login(
      nim: '2341720001',
      password: 'mahasiswa123',
    );
  });

  group('2. Api Load Data Mahasiswa', () {
    test('loadProfile returns student profile', () async {
      final profile = await studentDataService.loadProfile();
      expect(profile.studentId, '2341720001');
      expect(profile.role, 'Mahasiswa');
      expect(profile.fullName.isNotEmpty, isTrue);
    });

    test('loadSchedules returns list of class schedules', () async {
      final schedules = await studentDataService.loadSchedules(dayOfWeek: 3);
      expect(schedules, isNotEmpty);
      expect(schedules.first.dayOfWeek, 3);
      expect(schedules.first.courseName.isNotEmpty, isTrue);
    });

    test('loadAttendanceSummary returns attendance statistics', () async {
      final summary = await studentDataService.loadAttendanceSummary();
      expect(summary.hadir, isNonNegative);
      expect(summary.izin, isNonNegative);
      expect(summary.sakit, isNonNegative);
      expect(summary.alfa, isNonNegative);
    });

    test(
      'loadClassReminder returns upcoming reminder when available',
      () async {
        final reminder = await studentDataService.loadClassReminder();
        if (reminder != null) {
          expect(reminder.courseName.isNotEmpty, isTrue);
          expect(reminder.time.isNotEmpty, isTrue);
        }
      },
    );
  });

  group('3. CRUD Operations', () {
    test('CRUD Data Mahasiswa (Create, Read, Update, Delete)', () async {
      await ensureWhitelisted(testNim);
      addTearDown(adminAuthRepository.logout);
      await studentDataService.deleteMahasiswa(testNim);

      try {
        // CREATE
        final created = await studentDataService.createMahasiswa(
          nim: testNim,
          namaLengkap: 'Mahasiswa Baru QA',
          email: 'qa@student.polinema.ac.id',
          noHp: '081299998888',
          kelas: 'TI-3A',
          prodi: 'D4-TI',
        );
        expect(created, isTrue);

        // READ
        final list = await studentDataService.listMahasiswa(
          search: 'Mahasiswa Baru QA',
        );
        expect(list.any((m) => m['nim'] == testNim), isTrue);

        // UPDATE
        final updated = await studentDataService.updateMahasiswa(
          testNim,
          namaLengkap: 'Mahasiswa QA Updated',
          noHp: '081200000000',
        );
        expect(updated, isTrue);

        // DELETE
        final deleted = await studentDataService.deleteMahasiswa(testNim);
        expect(deleted, isTrue);
      } finally {
        // Bersihkan sisa data agar test dapat diulang.
        await studentDataService.deleteMahasiswa(testNim);
        await removeWhitelisted(testNim);
      }
    });

    test(
      'CRUD Pengajuan Surat Ketidakhadiran (Create, Read, Update, Delete)',
      () async {
        String? pengajuanId;
        try {
          // CREATE
          final res = await studentDataService.submitPengajuan(
            jenis: 'izin',
            alasan: 'Lomba Robotika Nasional',
            matakuliah: 'Pemrograman Web',
            tanggal: '2026-11-20',
            dokumenPath: 'robotika.pdf',
          );
          expect(res['data'], isNotNull);
          pengajuanId = res['data']['id'] as String;

          // READ
          final list = await studentDataService.loadPengajuanList();
          expect(list.any((p) => p['id'] == pengajuanId), isTrue);

          // UPDATE
          final updated = await studentDataService.updatePengajuan(
            pengajuanId: pengajuanId,
            alasan: 'Lomba Robotika Nasional (Final)',
          );
          expect(updated, isTrue);
        } finally {
          // DELETE
          if (pengajuanId != null) {
            final deleted = await studentDataService.deletePengajuan(
              pengajuanId,
            );
            expect(deleted, isTrue);
          }
        }
      },
    );
  });
}
